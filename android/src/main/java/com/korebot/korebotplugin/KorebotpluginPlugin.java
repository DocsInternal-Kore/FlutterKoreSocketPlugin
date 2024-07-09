package com.korebot.korebotplugin;

import android.content.Context;
import android.content.SharedPreferences;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import org.apache.commons.lang3.StringUtils;

import java.io.IOException;
import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import kore.botssdk.bot.BotClient;
import kore.botssdk.event.KoreEventCenter;
import kore.botssdk.models.CallBackEventModel;
import kore.botssdk.models.JWTTokenResponse;
import kore.botssdk.net.BotJWTRestBuilder;
import kore.botssdk.net.BotRestBuilder;
import kore.botssdk.net.RestBuilder;
import kore.botssdk.net.SDKConfiguration;
import kore.botssdk.utils.LogUtils;
import kore.botssdk.websocket.SocketConnectionListener;
import kore.botssdk.websocket.SocketWrapper;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

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
    final Gson gson = new Gson();
    BotClient botClient;
    SharedPreferences sharedPreferences;
    String PREF_NAME = "Kore_Bot_Pref";
    String JWT_TOKEN = "JWT_TOKEN";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "kore.botsdk/chatbot");
        channel.setMethodCallHandler(this);
        context = flutterPluginBinding.getApplicationContext();
        sharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        KoreEventCenter.register(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getChatWindow":
                SDKConfiguration.Client.bot_id = call.argument("botId");
                SDKConfiguration.Client.client_secret = call.argument("clientSecret");
                SDKConfiguration.Client.client_id = call.argument("clientId");
                SDKConfiguration.Client.bot_name = call.argument("chatBotName");
                SDKConfiguration.Client.identity = call.argument("identity");
                SDKConfiguration.Client.isReconnect = Boolean.TRUE.equals(call.argument("isReconnect"));
                SDKConfiguration.Server.SERVER_URL = call.argument("server_url");
                SDKConfiguration.setJwtServerUrl(call.argument("jwt_server_url"));

                if (StringUtils.isNotEmpty(call.argument("jwtToken"))) {
                    SDKConfiguration.JWTServer.setJwt_token(call.argument("jwtToken"));
                    sharedPreferences.edit().putString(JWT_TOKEN, call.argument("jwtToken")).apply();
                } else if (StringUtils.isEmpty(sharedPreferences.getString(JWT_TOKEN, ""))) makeStsJwtCallWithConfig(true);

                botClient = new BotClient(context);

                //Initiating bot connection once connected callbacks will be fired on respective actions
                botClient.connectAsAnonymousUser(sharedPreferences.getString(JWT_TOKEN, ""), SDKConfiguration.Client.bot_name, SDKConfiguration.Client.bot_id, socketConnectionListener, SDKConfiguration.Client.isReconnect);
                break;
            case "sendMessage":
                botClient.sendMessage(call.argument("message"));
                break;
            case "initialize":
                SDKConfiguration.Client.bot_id = call.argument("botId");
                SDKConfiguration.Client.client_secret = call.argument("clientSecret");
                SDKConfiguration.Client.client_id = call.argument("clientId");
                SDKConfiguration.Client.bot_name = call.argument("chatBotName");
                SDKConfiguration.Client.identity = call.argument("identity");
                SDKConfiguration.Client.isReconnect = Boolean.TRUE.equals(call.argument("callHistory"));

                SDKConfiguration.Server.SERVER_URL = call.argument("server_url");
                SDKConfiguration.Server.KORE_BOT_SERVER_URL = call.argument("server_url");
                SDKConfiguration.setJwtServerUrl(call.argument("jwt_server_url"));

                if (StringUtils.isNotEmpty(call.argument("jwtToken"))) {
                    SDKConfiguration.JWTServer.setJwt_token(call.argument("jwtToken"));
                    sharedPreferences.edit().putString(JWT_TOKEN, call.argument("jwtToken")).apply();
                } else {
                    //For jwtToken
                    makeStsJwtCallWithConfig(false);
                }
                break;
            case "getSearchResults":
                getSearchResults(call.argument("searchQuery"));
                break;
            case "getHistoryResults":
                getHistoryResults(call.argument("offset"), call.argument("limit"));
                break;
            case "closeBot":
                if (botClient != null) botClient.disconnect();
                break;

        }
    }

    SocketConnectionListener socketConnectionListener = new SocketConnectionListener() {
        @Override
        public void onOpen(boolean b) {
            channel.invokeMethod("Callbacks", "Bot Connected Successfully");
            Toast.makeText(context, "Bot Connected Successfully", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void onClose(int i, String s) {
            channel.invokeMethod("Callbacks", "Bot disconnected Successfully");
            Toast.makeText(context, "Bot disconnected Successfully", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void onTextMessage(String payload) {
            channel.invokeMethod("Callbacks", payload);
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

        @Override
        public void onReconnectStopped(String reconnectionStopped) {
            channel.invokeMethod("Callbacks", "Unable to connect to the bot. Please try again later");
            Toast.makeText(context, "Unable to connect to the bot. Please try again later", Toast.LENGTH_SHORT).show();
        }
    };

    private void makeStsJwtCallWithConfig(boolean callBotConnect) {
        retrofit2.Call<JWTTokenResponse> getBankingConfigService = BotJWTRestBuilder.getBotJWTRestAPI().getJWTToken(getRequestObject());
        getBankingConfigService.enqueue(new Callback<JWTTokenResponse>() {
            @Override
            public void onResponse(@NonNull retrofit2.Call<JWTTokenResponse> call, @NonNull Response<JWTTokenResponse> response) {

                if (response.isSuccessful()) {
                    JWTTokenResponse jwtTokenResponse = response.body();
                    if (jwtTokenResponse != null) {
                        String jwt = jwtTokenResponse.getJwt();
                        sharedPreferences.edit().putString(JWT_TOKEN, jwt).apply();

                        if (callBotConnect) {
                            botClient = new BotClient(context);

                            //Initiating bot connection once connected callbacks will be fired on respective actions
                            botClient.connectAsAnonymousUser(sharedPreferences.getString(JWT_TOKEN, ""), SDKConfiguration.Client.bot_name, SDKConfiguration.Client.bot_id, socketConnectionListener, SDKConfiguration.Client.isReconnect);
                        }
                    }
                }
            }

            @Override
            public void onFailure(@NonNull Call<JWTTokenResponse> call, @NonNull Throwable t) {
                LogUtils.d("token refresh", t.getMessage());
            }
        });
    }

    private void getSearchResults(String searchQuery) {
        retrofit2.Call<ResponseBody> getBankingConfigService = BotRestBuilder.getBotRestService().getAdvancedSearch(SDKConfiguration.Client.bot_id, sharedPreferences.getString(JWT_TOKEN, ""), getSearchObject(searchQuery));
        getBankingConfigService.enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(@NonNull retrofit2.Call<ResponseBody> call, @NonNull Response<ResponseBody> response) {

                if (response.isSuccessful()) {
                    try {
                        if (response.body() != null) channel.invokeMethod("Callbacks", new Gson().toJson(response.body().string()));
                        else channel.invokeMethod("Callbacks", "No response received.");
                    } catch (IOException e) {
                        channel.invokeMethod("Callbacks", "No response received.");
                        throw new RuntimeException(e);
                    }
                } else {
                    channel.invokeMethod("Callbacks", "No response received.");
                }
            }

            @Override
            public void onFailure(@NonNull Call<ResponseBody> call, @NonNull Throwable t) {
                LogUtils.d("token refresh", t.getMessage());
            }
        });
    }

    private void getHistoryResults(final int _offset, final int limit) {
        retrofit2.Call<ResponseBody> getBankingConfigService = RestBuilder.getRestAPI().getBotHistory("bearer " + SocketWrapper.getInstance(context).getAccessToken(), SDKConfiguration.Client.bot_id, limit, _offset, true);
        getBankingConfigService.enqueue(new Callback<>() {
            @Override
            public void onResponse(@NonNull retrofit2.Call<ResponseBody> call, @NonNull Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    try {
                        if (response.body() != null) channel.invokeMethod("Callbacks", new Gson().toJson(response.body().string()));
                        else channel.invokeMethod("Callbacks", "No response received.");
                    } catch (Exception e) {
                        channel.invokeMethod("Callbacks", "No response received.");
                        throw new RuntimeException(e);
                    }
                } else {
                    channel.invokeMethod("Callbacks", "No response received.");
                }
            }

            @Override
            public void onFailure(@NonNull Call<ResponseBody> call, @NonNull Throwable t) {
                LogUtils.d("token refresh", t.getMessage());
            }
        });
    }

    private HashMap<String, Object> getRequestObject() {
        HashMap<String, Object> hsh = new HashMap<>();
        hsh.put("clientId", SDKConfiguration.Client.client_id);
        hsh.put("clientSecret", SDKConfiguration.Client.client_secret);
        hsh.put("identity", SDKConfiguration.Client.identity);
        hsh.put("aud", "https://idproxy.kore.com/authorize");
        hsh.put("isAnonymous", false);

        return hsh;
    }

    private HashMap<String, Object> getSearchObject(String query) {
        HashMap<String, Object> hsh = new HashMap<>();
        hsh.put("query", query);
        return hsh;
    }

    public void onEvent(CallBackEventModel callBackEventModel) {
        channel.invokeMethod("Callbacks", gson.toJson(callBackEventModel));
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        KoreEventCenter.unregister(this);
    }
}
