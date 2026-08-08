#include <curl/curl.h>
#include <jni.h>
#include <openssl/evp.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cctype>
#include <cstdint>
#include <mutex>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>
#include <unistd.h>

namespace {

struct NativeResponse {
  long status_code = 0;
  std::string body;
  std::string effective_url;
  std::vector<std::string> headers;
  std::vector<std::string> ech_logs;
  std::string ech_status = "unavailable";
};

struct CachedEchConfig {
  std::string value;
  std::chrono::steady_clock::time_point expires_at;
};

std::mutex ech_cache_mutex;
std::unordered_map<std::string, CachedEchConfig> ech_cache;
std::mutex gateway_cache_mutex;
std::unordered_map<std::string, CachedEchConfig> gateway_cache;
std::mutex curl_share_mutex;
std::once_flag curl_share_once;
CURLSH* curl_share = nullptr;

void curl_share_lock(CURL*, curl_lock_data, curl_lock_access, void*) {
  curl_share_mutex.lock();
}

void curl_share_unlock(CURL*, curl_lock_data, void*) {
  curl_share_mutex.unlock();
}

CURLSH* shared_curl() {
  std::call_once(curl_share_once, [] {
    curl_share = curl_share_init();
    if (curl_share == nullptr) return;
    curl_share_setopt(curl_share, CURLSHOPT_LOCKFUNC, curl_share_lock);
    curl_share_setopt(curl_share, CURLSHOPT_UNLOCKFUNC, curl_share_unlock);
    curl_share_setopt(curl_share, CURLSHOPT_SHARE, CURL_LOCK_DATA_DNS);
    curl_share_setopt(curl_share, CURLSHOPT_SHARE, CURL_LOCK_DATA_SSL_SESSION);
  });
  return curl_share;
}

size_t write_callback(char* data, size_t size, size_t count, void* user_data) {
  auto* response = static_cast<NativeResponse*>(user_data);
  response->body.append(data, size * count);
  return size * count;
}

size_t header_callback(char* data, size_t size, size_t count, void* user_data) {
  auto* response = static_cast<NativeResponse*>(user_data);
  std::string line(data, size * count);
  if (line.rfind("HTTP/", 0) == 0) {
    response->headers.clear();
  } else if (const auto separator = line.find(':'); separator != std::string::npos) {
    auto name = line.substr(0, separator);
    auto value = line.substr(separator + 1);
    while (!value.empty() && std::isspace(static_cast<unsigned char>(value.back()))) value.pop_back();
    while (!value.empty() && std::isspace(static_cast<unsigned char>(value.front()))) value.erase(value.begin());
    response->headers.push_back(name + "\t" + value);
  }
  return size * count;
}

std::string escape_json(const std::string& value) {
  std::string escaped;
  escaped.reserve(value.size());
  for (const auto character : value) {
    switch (character) {
      case '\\': escaped += "\\\\"; break;
      case '"': escaped += "\\\""; break;
      case '\n': escaped += "\\n"; break;
      case '\r': escaped += "\\r"; break;
      case '\t': escaped += "\\t"; break;
      default: escaped += character;
    }
  }
  return escaped;
}

std::string encode_base64(const std::string& value) {
  std::string encoded(4 * ((value.size() + 2) / 3), '\0');
  encoded.resize(4 * ((value.size() + 2) / 3));
  EVP_EncodeBlock(reinterpret_cast<unsigned char*>(encoded.data()), reinterpret_cast<const unsigned char*>(value.data()), static_cast<int>(value.size()));
  return encoded;
}

std::string ech_config_from_response(const std::string& body) {
  const auto marker = body.find("ech=");
  if (marker != std::string::npos) {
    auto start = marker + 4;
    if (start < body.size() && body[start] == '"') ++start;
    auto end = start;
    while (end < body.size() && (std::isalnum(static_cast<unsigned char>(body[end])) || body[end] == '+' || body[end] == '/' || body[end] == '=' || body[end] == '-' || body[end] == '_')) ++end;
    if (end > start) return body.substr(start, end - start);
  }

  const auto wire_marker = body.find("\\\\# ");
  if (wire_marker == std::string::npos) return {};
  const auto data_start = body.find(' ', wire_marker + 4);
  if (data_start == std::string::npos) return {};
  std::vector<unsigned char> wire;
  for (size_t index = data_start + 1; index + 1 < body.size();) {
    if (std::isxdigit(static_cast<unsigned char>(body[index])) && std::isxdigit(static_cast<unsigned char>(body[index + 1]))) {
      const auto hex = body.substr(index, 2);
      wire.push_back(static_cast<unsigned char>(std::stoi(hex, nullptr, 16)));
      index += 2;
    } else if (body[index] == ' ' || body[index] == '"') {
      ++index;
    } else {
      break;
    }
  }
  if (wire.size() < 3) return {};
  size_t position = 2;
  while (position < wire.size() && wire[position] != 0) {
    const auto label_length = wire[position];
    if (label_length > 63 || position + label_length >= wire.size()) return {};
    position += label_length + 1;
  }
  if (position >= wire.size()) return {};
  ++position;
  while (position + 4 <= wire.size()) {
    const auto key = static_cast<unsigned int>(wire[position]) << 8 | wire[position + 1];
    const auto value_length = static_cast<unsigned int>(wire[position + 2]) << 8 | wire[position + 3];
    position += 4;
    if (position + value_length > wire.size()) return {};
    if (key == 5) {
      std::string encoded(4 * ((value_length + 2) / 3), '\0');
      EVP_EncodeBlock(reinterpret_cast<unsigned char*>(encoded.data()), wire.data() + position, value_length);
      return encoded;
    }
    position += value_length;
  }
  return {};
}

std::string doh_query_url(const std::string& doh_url, const std::string& host) {
  return doh_url + (doh_url.find('?') == std::string::npos ? "?" : "&") + "name=" + host + "&type=65";
}

void add_ech_log(NativeResponse* response, const std::string& message) {
  response->ech_logs.push_back(message);
}

std::string request_host(const std::string& url);

std::string bootstrap_gateway_ip(const std::string& host, bool* cache_hit) {
  {
    std::lock_guard lock(gateway_cache_mutex);
    const auto entry = gateway_cache.find(host);
    if (entry != gateway_cache.end() && std::chrono::steady_clock::now() < entry->second.expires_at) {
      *cache_hit = true;
      return entry->second.value;
    }
  }
  std::array<unsigned char, 512> query{};
  const auto id = static_cast<uint16_t>(std::chrono::steady_clock::now().time_since_epoch().count());
  query[0] = static_cast<unsigned char>(id >> 8);
  query[1] = static_cast<unsigned char>(id);
  query[2] = 1;
  query[5] = 1;
  size_t offset = 12;
  size_t start = 0;
  while (start < host.size()) {
    const auto end = host.find('.', start);
    const auto length = (end == std::string::npos ? host.size() : end) - start;
    if (length == 0 || length > 63 || offset + length + 5 > query.size()) return {};
    query[offset++] = static_cast<unsigned char>(length);
    std::copy_n(host.data() + start, length, query.data() + offset);
    offset += length;
    start = end == std::string::npos ? host.size() : end + 1;
  }
  query[offset++] = 0;
  query[offset++] = 0;
  query[offset++] = 1;
  query[offset++] = 0;
  query[offset++] = 1;
  const auto socket_fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (socket_fd < 0) return {};
  timeval timeout{5, 0};
  setsockopt(socket_fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
  sockaddr_in address{};
  address.sin_family = AF_INET;
  address.sin_port = htons(53);
  inet_pton(AF_INET, "223.5.5.5", &address.sin_addr);
  if (sendto(socket_fd, query.data(), offset, 0, reinterpret_cast<sockaddr*>(&address), sizeof(address)) < 0) {
    close(socket_fd);
    return {};
  }
  std::array<unsigned char, 512> reply{};
  const auto length = recvfrom(socket_fd, reply.data(), reply.size(), 0, nullptr, nullptr);
  close(socket_fd);
  if (length < 12 || reply[0] != query[0] || reply[1] != query[1]) return {};
  auto skip_name = [&](size_t* position) {
    while (*position < static_cast<size_t>(length)) {
      const auto label = reply[(*position)++];
      if (label == 0) return true;
      if ((label & 0xc0) == 0xc0) return ++*position <= static_cast<size_t>(length);
      if (label > 63 || *position + label > static_cast<size_t>(length)) return false;
      *position += label;
    }
    return false;
  };
  size_t position = 12;
  if (!skip_name(&position) || position + 4 > static_cast<size_t>(length)) return {};
  position += 4;
  const auto answers = static_cast<unsigned int>(reply[6]) << 8 | reply[7];
  for (unsigned int index = 0; index < answers; ++index) {
    if (!skip_name(&position) || position + 10 > static_cast<size_t>(length)) return {};
    const auto type = static_cast<unsigned int>(reply[position]) << 8 | reply[position + 1];
    const auto data_length = static_cast<unsigned int>(reply[position + 8]) << 8 | reply[position + 9];
    position += 10;
    if (position + data_length > static_cast<size_t>(length)) return {};
    if (type == 1 && data_length == 4) {
      char ip[INET_ADDRSTRLEN]{};
      inet_ntop(AF_INET, reply.data() + position, ip, sizeof(ip));
      std::string result = ip;
      std::lock_guard lock(gateway_cache_mutex);
      gateway_cache[host] = CachedEchConfig{result, std::chrono::steady_clock::now() + std::chrono::minutes(5)};
      return result;
    }
    position += data_length;
  }
  return {};
}

std::string fetch_ech_config(const std::string& doh_url, const std::string& doh_resolve, const std::string& host, NativeResponse* diagnostics) {
  const auto cache_key = doh_url + '\n' + host;
  {
    std::lock_guard lock(ech_cache_mutex);
    const auto entry = ech_cache.find(cache_key);
    if (entry != ech_cache.end() && std::chrono::steady_clock::now() < entry->second.expires_at) {
      add_ech_log(diagnostics, "ECH configuration cache hit for " + host);
      return entry->second.value;
    }
  }
  auto* handle = curl_easy_init();
  if (handle == nullptr) return {};
  if (auto* share = shared_curl(); share != nullptr) curl_easy_setopt(handle, CURLOPT_SHARE, share);
  NativeResponse response;
  auto* headers = curl_slist_append(nullptr, "Accept: application/dns-json");
  const auto doh_host = request_host(doh_url);
  bool gateway_cache_hit = false;
  const auto bootstrap_ip = doh_resolve.empty() ? bootstrap_gateway_ip(doh_host, &gateway_cache_hit) : std::string{};
  const auto resolver_entry = !doh_resolve.empty() ? doh_resolve : (bootstrap_ip.empty() ? std::string{} : doh_host + ":443:" + bootstrap_ip);
  if (!resolver_entry.empty()) add_ech_log(diagnostics, gateway_cache_hit ? std::string("Gateway bootstrap cache hit") : "Gateway bootstrap: " + resolver_entry);
  else add_ech_log(diagnostics, "Gateway bootstrap failed, using system DNS");
  curl_slist* resolver_entries = resolver_entry.empty() ? nullptr : curl_slist_append(nullptr, resolver_entry.c_str());
  curl_easy_setopt(handle, CURLOPT_URL, doh_query_url(doh_url, host).c_str());
  curl_easy_setopt(handle, CURLOPT_HTTPHEADER, headers);
  curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, write_callback);
  curl_easy_setopt(handle, CURLOPT_WRITEDATA, &response);
  curl_easy_setopt(handle, CURLOPT_FOLLOWLOCATION, 1L);
  curl_easy_setopt(handle, CURLOPT_DNS_CACHE_TIMEOUT, 300L);
  curl_easy_setopt(handle, CURLOPT_CONNECTTIMEOUT, 10L);
  curl_easy_setopt(handle, CURLOPT_TIMEOUT, 15L);
  curl_easy_setopt(handle, CURLOPT_SSLVERSION, CURL_SSLVERSION_TLSv1_3);
  curl_easy_setopt(handle, CURLOPT_SSL_OPTIONS, CURLSSLOPT_NATIVE_CA);
  curl_easy_setopt(handle, CURLOPT_CAPATH, "/system/etc/security/cacerts");
  if (resolver_entries != nullptr) curl_easy_setopt(handle, CURLOPT_RESOLVE, resolver_entries);
  const auto result = curl_easy_perform(handle);
  curl_easy_getinfo(handle, CURLINFO_RESPONSE_CODE, &response.status_code);
  curl_slist_free_all(headers);
  curl_slist_free_all(resolver_entries);
  curl_easy_cleanup(handle);
  if (result != CURLE_OK) add_ech_log(diagnostics, "ECH lookup failed for " + host + ": " + curl_easy_strerror(result));
  else add_ech_log(diagnostics, "ECH lookup HTTP " + std::to_string(response.status_code) + " for " + host);
  const auto config = result == CURLE_OK && response.status_code == 200 ? ech_config_from_response(response.body) : std::string{};
  if (!config.empty()) {
    std::lock_guard lock(ech_cache_mutex);
    ech_cache[cache_key] = CachedEchConfig{config, std::chrono::steady_clock::now() + std::chrono::minutes(30)};
  }
  add_ech_log(diagnostics, config.empty() ? "No ECH configuration for " + host : "ECH configuration loaded for " + host + " (" + std::to_string(config.size()) + " base64 bytes)");
  return config;
}

std::string request_host(const std::string& url) {
  CURLU* parsed = curl_url();
  if (parsed == nullptr) return {};
  curl_url_set(parsed, CURLUPART_URL, url.c_str(), 0);
  char* host = nullptr;
  curl_url_get(parsed, CURLUPART_HOST, &host, 0);
  std::string result = host == nullptr ? "" : host;
  curl_free(host);
  curl_url_cleanup(parsed);
  return result;
}

std::string json_response(const NativeResponse& response) {
  std::string json = "{\"statusCode\":" + std::to_string(response.status_code) + ",\"url\":\"" + escape_json(response.effective_url) + "\",\"body\":\"" + encode_base64(response.body) + "\",\"echStatus\":\"" + response.ech_status + "\",\"echLogs\":[";
  for (size_t index = 0; index < response.ech_logs.size(); ++index) {
    if (index > 0) json += ',';
    json += '"' + escape_json(response.ech_logs[index]) + '"';
  }
  json += "],\"headers\":[";
  for (size_t index = 0; index < response.headers.size(); ++index) {
    if (index > 0) json += ',';
    json += '"' + escape_json(response.headers[index]) + '"';
  }
  return json + "]}";
}

std::string to_string(JNIEnv* env, jstring value) {
  const auto* chars = env->GetStringUTFChars(value, nullptr);
  std::string result(chars);
  env->ReleaseStringUTFChars(value, chars);
  return result;
}

void throw_exception(JNIEnv* env, const char* message) {
  const auto exception = env->FindClass("java/io/IOException");
  env->ThrowNew(exception, message);
}

}

extern "C" JNIEXPORT jstring JNICALL
Java_com_liar_han1meplus_EchHttpClient_request(
    JNIEnv* env,
    jclass,
    jstring method,
    jstring url,
    jobjectArray headers,
    jbyteArray body,
    jstring doh_url,
    jstring doh_resolve) {
  static const auto initialized = curl_global_init(CURL_GLOBAL_DEFAULT) == CURLE_OK;
  if (!initialized) {
    throw_exception(env, "Unable to initialize libcurl");
    return nullptr;
  }

  auto* handle = curl_easy_init();
  if (handle == nullptr) {
    throw_exception(env, "Unable to create a libcurl request");
    return nullptr;
  }
  if (auto* share = shared_curl(); share != nullptr) curl_easy_setopt(handle, CURLOPT_SHARE, share);

  const auto request_method = to_string(env, method);
  const auto request_url = to_string(env, url);
  const auto resolver_url = to_string(env, doh_url);
  const auto resolver_address = to_string(env, doh_resolve);
  NativeResponse response;
  curl_slist* request_headers = nullptr;
  curl_slist* resolver_entries = nullptr;
  std::vector<jbyte> request_body;

  for (jsize index = 0; index < env->GetArrayLength(headers); ++index) {
    const auto header = static_cast<jstring>(env->GetObjectArrayElement(headers, index));
    request_headers = curl_slist_append(request_headers, to_string(env, header).c_str());
    env->DeleteLocalRef(header);
  }
  if (body != nullptr) {
    const auto length = env->GetArrayLength(body);
    request_body.resize(length);
    env->GetByteArrayRegion(body, 0, length, request_body.data());
  }

  curl_easy_setopt(handle, CURLOPT_URL, request_url.c_str());
  curl_easy_setopt(handle, CURLOPT_HTTPHEADER, request_headers);
  curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, write_callback);
  curl_easy_setopt(handle, CURLOPT_WRITEDATA, &response);
  curl_easy_setopt(handle, CURLOPT_HEADERFUNCTION, header_callback);
  curl_easy_setopt(handle, CURLOPT_HEADERDATA, &response);
  curl_easy_setopt(handle, CURLOPT_USERAGENT, "Han1me+/1.0");
  curl_easy_setopt(handle, CURLOPT_FOLLOWLOCATION, 1L);
  curl_easy_setopt(handle, CURLOPT_MAXREDIRS, 5L);
  curl_easy_setopt(handle, CURLOPT_DNS_CACHE_TIMEOUT, 300L);
  curl_easy_setopt(handle, CURLOPT_CONNECTTIMEOUT, 15L);
  curl_easy_setopt(handle, CURLOPT_TIMEOUT, 60L);
  curl_easy_setopt(handle, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1);
  curl_easy_setopt(handle, CURLOPT_SSLVERSION, CURL_SSLVERSION_TLSv1_3);
  curl_easy_setopt(handle, CURLOPT_SSL_OPTIONS, CURLSSLOPT_NATIVE_CA);
  curl_easy_setopt(handle, CURLOPT_CAPATH, "/system/etc/security/cacerts");
  curl_easy_setopt(handle, CURLOPT_DOH_URL, resolver_url.c_str());
  const auto host = request_host(request_url);
  auto ech_config = fetch_ech_config(resolver_url, resolver_address, host, &response);
  if (!ech_config.empty()) response.ech_status = "target configuration loaded";
  if (ech_config.empty()) {
    ech_config = fetch_ech_config(resolver_url, resolver_address, "store.ubisoft.com", &response);
    if (!ech_config.empty()) response.ech_status = "shared configuration loaded";
  }
  if (ech_config.empty()) {
    curl_easy_setopt(handle, CURLOPT_ECH, "true");
    response.ech_status = "no ECH configuration available";
  } else {
    const auto option = "ecl:" + ech_config;
    curl_easy_setopt(handle, CURLOPT_ECH, option.c_str());
  }
  const auto doh_host = request_host(resolver_url);
  bool gateway_cache_hit = false;
  const auto bootstrap_ip = resolver_address.empty() ? bootstrap_gateway_ip(doh_host, &gateway_cache_hit) : std::string{};
  const auto resolver_entry = !resolver_address.empty() ? resolver_address : (bootstrap_ip.empty() ? std::string{} : doh_host + ":443:" + bootstrap_ip);
  if (!resolver_entry.empty()) {
    add_ech_log(&response, gateway_cache_hit ? std::string("Gateway bootstrap cache hit") : "Gateway bootstrap: " + resolver_entry);
    resolver_entries = curl_slist_append(resolver_entries, resolver_entry.c_str());
    curl_easy_setopt(handle, CURLOPT_RESOLVE, resolver_entries);
  } else {
    add_ech_log(&response, "Gateway bootstrap failed, using system DNS");
  }

  if (request_method == "POST") {
    curl_easy_setopt(handle, CURLOPT_POST, 1L);
  } else if (request_method == "DELETE") {
    curl_easy_setopt(handle, CURLOPT_CUSTOMREQUEST, "DELETE");
  } else if (request_method != "GET") {
    curl_easy_setopt(handle, CURLOPT_CUSTOMREQUEST, request_method.c_str());
  }
  if (!request_body.empty()) {
    curl_easy_setopt(handle, CURLOPT_POSTFIELDS, request_body.data());
    curl_easy_setopt(handle, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(request_body.size()));
  }

  const auto result = curl_easy_perform(handle);
  if (result != CURLE_OK) {
    const auto* error = curl_easy_strerror(result);
    curl_slist_free_all(request_headers);
    curl_slist_free_all(resolver_entries);
    curl_easy_cleanup(handle);
    throw_exception(env, error);
    return nullptr;
  }

  char* effective_url = nullptr;
  curl_easy_getinfo(handle, CURLINFO_RESPONSE_CODE, &response.status_code);
  curl_easy_getinfo(handle, CURLINFO_EFFECTIVE_URL, &effective_url);
  response.effective_url = effective_url == nullptr ? request_url : effective_url;
  if (response.ech_status == "target configuration loaded") response.ech_status = "ECH accepted with target configuration";
  if (response.ech_status == "shared configuration loaded") response.ech_status = "ECH accepted with shared configuration";
  const auto json = json_response(response);
  curl_slist_free_all(request_headers);
  curl_slist_free_all(resolver_entries);
  curl_easy_cleanup(handle);
  return env->NewStringUTF(json.c_str());
}
