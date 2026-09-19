#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <filesystem>
#include <memory>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {

void ApplyPerMonitorDpiAwareness() {
  if (!SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)) {
    SetProcessDPIAware();
  }
}

UINT SystemDpi() {
  const auto dpi = GetDpiForSystem();
  if (dpi != 0) return dpi;
  const auto screen = GetDC(nullptr);
  if (screen == nullptr) return 96;
  const auto result = static_cast<UINT>(GetDeviceCaps(screen, LOGPIXELSX));
  ReleaseDC(nullptr, screen);
  return result == 0 ? 96 : result;
}

int DpiScale(int value, UINT dpi) {
  return static_cast<int>(static_cast<double>(value) * dpi / 96.0 + 0.5);
}

}

struct AppWindow {
  std::unique_ptr<flutter::FlutterViewController> controller;
};

void ConfigureWebViewUserDataFolder() {
  const auto length = GetEnvironmentVariableW(L"LOCALAPPDATA", nullptr, 0);
  if (length == 0) return;
  std::wstring local_app_data(length, L'\0');
  GetEnvironmentVariableW(L"LOCALAPPDATA", local_app_data.data(), length);
  local_app_data.resize(length - 1);
  const auto user_data_folder = std::filesystem::path(local_app_data) / L"Han1mePlus" / L"webview2";
  std::error_code error;
  std::filesystem::create_directories(user_data_folder, error);
  if (!error) SetEnvironmentVariableW(L"WEBVIEW2_USER_DATA_FOLDER", user_data_folder.c_str());
}

LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  auto* app = reinterpret_cast<AppWindow*>(GetWindowLongPtr(window, GWLP_USERDATA));
  if (message == WM_NCCREATE) {
    app = static_cast<AppWindow*>(reinterpret_cast<CREATESTRUCT*>(lparam)->lpCreateParams);
    SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(app));
  }
  if (app != nullptr && app->controller != nullptr) {
    const auto result = app->controller->HandleTopLevelWindowProc(window, message, wparam, lparam);
    if (result.has_value()) return result.value();
  }
  switch (message) {
    case WM_GETMINMAXINFO: {
      auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
      const auto dpi = GetDpiForWindow(window);
      info->ptMinTrackSize.x = DpiScale(720, dpi);
      info->ptMinTrackSize.y = DpiScale(540, dpi);
      return 0;
    }
    case WM_SIZE:
      if (app != nullptr && app->controller != nullptr) {
        const auto child = app->controller->view()->GetNativeWindow();
        MoveWindow(child, 0, 0, LOWORD(lparam), HIWORD(lparam), TRUE);
      }
      return 0;
    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;
  }
  return DefWindowProc(window, message, wparam, lparam);
}

int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE, wchar_t*, int show_command) {
  ApplyPerMonitorDpiAwareness();
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  ConfigureWebViewUserDataFolder();
  const wchar_t class_name[] = L"Han1mePlusWindow";
  WNDCLASS window_class{};
  window_class.hInstance = instance;
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.hIcon = LoadIcon(instance, MAKEINTRESOURCE(IDI_APP_ICON));
  window_class.lpszClassName = class_name;
  window_class.lpfnWndProc = WindowProc;
  RegisterClass(&window_class);

  AppWindow app;
  const auto dpi = SystemDpi();
  const auto width = DpiScale(1280, dpi);
  const auto height = DpiScale(720, dpi);
  const auto window = CreateWindow(class_name, L"Han1me+", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, width, height, nullptr, nullptr, instance, &app);
  if (window == nullptr) return EXIT_FAILURE;

  RECT bounds{};
  GetClientRect(window, &bounds);
  flutter::DartProject project(L"data");
  app.controller = std::make_unique<flutter::FlutterViewController>(bounds.right, bounds.bottom, project);
  if (!app.controller->engine() || !app.controller->view()) return EXIT_FAILURE;
  RegisterPlugins(app.controller->engine());
  const auto flutter_view = app.controller->view()->GetNativeWindow();
  SetParent(flutter_view, window);
  SetFocus(flutter_view);
  app.controller->engine()->SetNextFrameCallback([window]() { ShowWindow(window, SW_SHOWNORMAL); });
  app.controller->ForceRedraw();
  ShowWindow(window, show_command);

  MSG message;
  while (GetMessage(&message, nullptr, 0, 0)) {
    TranslateMessage(&message);
    DispatchMessage(&message);
  }
  CoUninitialize();
  return EXIT_SUCCESS;
}
