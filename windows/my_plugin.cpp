#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

class MyPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  MyPlugin();

  virtual ~MyPlugin();

  // Implements Plugin.
  void RegisterWithRegistrar(flutter::PluginRegistrar* registrar) override;

 private:
  // Handles incoming method calls.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

void MyPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "notifications",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<MyPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

MyPlugin::MyPlugin() {}

MyPlugin::~MyPlugin() {}

void MyPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("showNotification") == 0) {
    // Get the title and message from the method call arguments.
    auto arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("Invalid arguments", "Expected a map");
      return;
    }
    auto title = std::get_if<std::string>(&(*arguments)["title"]);
    auto message = std::get_if<std::string>(&(*arguments)["message"]);
    if (!title || !message) {
      result->Error("Invalid arguments", "Expected title and message strings");
      return;
    }

    // Show the notification using the title and message.
    // ...

    // Return a success result.
    result->Success(nullptr);
  } else {
    result->NotImplemented();
  }
}

flutter::DartExecutor::RunParams params = {};
params.vm_snapshot_data = ...;
params.icu_data = ...;
params.assets_path = ...;
params.packages_file_path = ...;

flutter::WindowsFlutterEngine engine(params);
auto registrar = std::make_unique<flutter::PluginRegistrarWindows>(
    engine.GetMessenger(), engine.GetBinaryMessenger());

MyPlugin::RegisterWithRegistrar(registrar.get());

engine.Run();

