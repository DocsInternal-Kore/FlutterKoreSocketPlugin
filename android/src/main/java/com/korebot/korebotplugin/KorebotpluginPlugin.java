package com.korebot.korebotplugin;

import android.content.Context;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import kore.botssdk.bot.BotClient;
import kore.botssdk.event.KoreEventCenter;
import kore.botssdk.models.CallBackEventModel;
import kore.botssdk.net.SDKConfiguration;
import kore.botssdk.websocket.SocketConnectionListener;

/**
 * KorebotpluginPlugin
 */
public class KorebotpluginPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    MethodChannel channel;
    Context context;
    private final Gson gson = new Gson();

    private BotClient botClient;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "kore.botsdk/chatbot");
        channel.setMethodCallHandler(this);
        context = flutterPluginBinding.getApplicationContext();
        KoreEventCenter.register(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getChatWindow")) {
            SDKConfiguration.Client.bot_id = "st-b9889c46-218c-58f7-838f-73ae9203488c";
            SDKConfiguration.Client.client_secret = "5OcBSQtH/k6Q/S6A3bseYfOee02YjjLLTNoT1qZDBso=";
            SDKConfiguration.Client.client_id = "cs-1e845b00-81ad-5757-a1e7-d0f6fea227e9";
            SDKConfiguration.Client.bot_name = "Bot SDK";
            SDKConfiguration.Client.identity = "anilkumar.routhu@kore.com";

            botClient = new BotClient(context);
            //Local library to generate JWT token can be replaced as per requirement
            String jwt = botClient.generateJWT(SDKConfiguration.Client.identity, SDKConfiguration.Client.client_secret, SDKConfiguration.Client.client_id, SDKConfiguration.Server.IS_ANONYMOUS_USER);

            //Initiating bot connection once connected callbacks will be fired on respective actions
            botClient.connectAsAnonymousUser(jwt, SDKConfiguration.Client.bot_name, SDKConfiguration.Client.bot_id, socketConnectionListener);

        } else if (call.method.equals("sendMessage")) {
            botClient.sendMessage(call.argument("message"));
        }
    }

    SocketConnectionListener socketConnectionListener = new SocketConnectionListener() {
        @Override
        public void onOpen(boolean b) {
            Toast.makeText(context, "Bot Connected Successfully", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void onClose(int i, String s) {
            Toast.makeText(context, "Bot disconnected Successfully", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void onTextMessage(String payload) {
            channel.invokeMethod("Callbacks", payload);
            Toast.makeText(context, payload, Toast.LENGTH_SHORT).show();
        }

        @Override
        public void onRawTextMessage(byte[] bytes) {

        }

        @Override
        public void onBinaryMessage(byte[] bytes) {

        }

        @Override
        public void refreshJwtToken() {

        }
    };

    public void onEvent(CallBackEventModel callBackEventModel) {
        channel.invokeMethod("Callbacks", gson.toJson(callBackEventModel));
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        KoreEventCenter.unregister(this);
    }
}
