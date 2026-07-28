#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <memory>

#include "flutter/generated_plugin_registrant.h"

struct AppWindow {
  std::unique_ptr<flutter::FlutterViewController> controller;
};

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
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  const wchar_t class_name[] = L"Han1mePlusWindow";
  WNDCLASS window_class{};
  window_class.hInstance = instance;
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = class_name;
  window_class.lpfnWndProc = WindowProc;
  RegisterClass(&window_class);

  AppWindow app;
  const auto window = CreateWindow(class_name, L"Han1me+", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 1280, 720, nullptr, nullptr, instance, &app);
  if (window == nullptr) return EXIT_FAILURE;

  RECT bounds{};
  GetClientRect(window, &bounds);
  flutter::DartProject project(L"data");
  app.controller = std::make_unique<flutter::FlutterViewController>(bounds.right, bounds.bottom, project);
  if (!app.controller->engine() || !app.controller->view()) return EXIT_FAILURE;
  RegisterPlugins(app.controller->engine());
  SetParent(app.controller->view()->GetNativeWindow(), window);
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
