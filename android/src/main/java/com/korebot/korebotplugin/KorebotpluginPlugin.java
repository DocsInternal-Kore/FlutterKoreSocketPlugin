package com.korebot.korebotplugin;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

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
import kore.botssdk.models.BotInfoModel;
import kore.botssdk.models.BotResponse;
import kore.botssdk.models.BotResponsePayLoadText;
import kore.botssdk.models.CallBackEventModel;
import kore.botssdk.models.JWTTokenResponse;
import kore.botssdk.models.RetailTokenResponse;
import kore.botssdk.net.BotJWTRestBuilder;
import kore.botssdk.net.RestBuilder;
import kore.botssdk.net.RestResponse;
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
    String RETAIL_JWT_TOKEN = "RETAIL_JWT_TOKEN";
    MethodCall missed_msg_call;

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
                SDKConfiguration.Server.KORE_BOT_SERVER_URL = call.argument("server_url");
                SDKConfiguration.setJwtServerUrl(call.argument("jwt_server_url"));

                HashMap<String, Object> data = call.argument("custom_data");
                if (data != null) {
                    RestResponse.BotCustomData customData = new RestResponse.BotCustomData();
                    customData.putAll(data);
                    SDKConfiguration.Server.setCustomData(customData);
                    botClient = new BotClient(context, customData);
                } else botClient = new BotClient(context);

                if (StringUtils.isNotEmpty(call.argument("jwtToken"))) {
                    SDKConfiguration.JWTServer.setJwt_token(call.argument("jwtToken"));
                    sharedPreferences.edit().putString(JWT_TOKEN, call.argument("jwtToken")).apply();

                    //Initiating bot connection once connected callbacks will be fired on respective actions
                    botClient.connectAsAnonymousUser(call.argument("jwtToken"), SDKConfiguration.Client.bot_name, SDKConfiguration.Client.bot_id, socketConnectionListener, SDKConfiguration.Client.isReconnect);
                } else makeStsJwtCallWithConfig();

                break;
            case "sendMessage":
                if (SocketWrapper.getInstance(context).isConnected()) {
                    botClient.sendMessage(call.argument("message"));
                } else if(isOnline()){
                    missed_msg_call = call;
                    channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("Send_Failed", "Socket disconnected, Trying to reconnect")));
                    SDKConfiguration.Client.isReconnect = true;
                    makeStsJwtCallWithConfig();
                }
                else {
                    channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("NoInternet", "No internet connection, Please try again later.")));
                }

                break;
            case "initialize":
                SDKConfiguration.Client.bot_id = call.argument("botId");
                SDKConfiguration.Client.indexName = call.argument("indexName");
                SDKConfiguration.Client.namespace = call.argument("namespace");
                SDKConfiguration.Client.stage = call.argument("stage");
                SDKConfiguration.Server.RETAIL_SERVER_URL = call.argument("retail_server_url");

                //For authorisation jwtToken
                getSearchAuthorisationToken();
                break;
            case "getSearchResults":
                HashMap<String, Object> context_data = call.argument("context_data");
                if (context_data != null) {
                    getSearchResults(call.argument("searchQuery"), context_data);
                } else getSearchResults(call.argument("searchQuery"));
                break;
            case "getHistoryResults":
                getHistoryResults(call.argument("offset"), call.argument("limit"));
                break;
            case "closeBot":
                if (botClient != null) botClient.disconnect();
                break;
            case "updateCustomData":
                    HashMap<String, Object> custom_data = call.argument("custom_data");
                    if (custom_data != null && botClient != null) {
                        if(botClient.getBotInfoModel() != null)
                            botClient.getBotInfoModel().customData.putAll(custom_data);
                        else
                        {
                            botClient.setBotInfoModel(new BotInfoModel(SDKConfiguration.Client.bot_name, SDKConfiguration.Client.bot_id, custom_data));
                        }

                        channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("UpdateCustomData", String.valueOf(true))));
                    }
                    else channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("UpdateCustomData", String.valueOf(false))));
                break;
            case "isSocketConnected":
                if (botClient != null)
                    channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("BotConnectStatus", String.valueOf(botClient.isConnected()))));
                else channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("BotConnectStatus", String.valueOf(false))));
        }
    }

    SocketConnectionListener socketConnectionListener = new SocketConnectionListener() {
        @Override
        public void onOpen(boolean b) {
            channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("BotConnected", "Bot connected Successfully")));

            if (missed_msg_call != null) {
                botClient.sendMessage(missed_msg_call.argument("message"));
                missed_msg_call = null;
            }
        }

        @Override
        public void onClose(int i, String s) {
            channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("BotDisconnected", "Bot disconnected")));
        }

        @Override
        public void onTextMessage(String payload) {
            try {
                final BotResponse botResponse = gson.fromJson(payload, BotResponse.class);
                if (botResponse == null || botResponse.getMessage() == null || botResponse.getMessage().isEmpty()) {
                    return;
                }

                channel.invokeMethod("Callbacks", new Gson().toJson(payload));

            } catch (Exception e) {
                try {
                    final BotResponsePayLoadText botResponse = gson.fromJson(payload, BotResponsePayLoadText.class);
                    if (botResponse == null || botResponse.getMessage() == null || botResponse.getMessage().isEmpty()) {
                        return;
                    }

                    channel.invokeMethod("Callbacks", new Gson().toJson(payload));

                } catch (Exception e2) {
                    e2.printStackTrace();
                }
            }
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
            channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("Error_Socket", "Unable to connect. Please try again later")));
        }
    };

    private void makeStsJwtCallWithConfig() {
        retrofit2.Call<JWTTokenResponse> getBankingConfigService = BotJWTRestBuilder.getBotJWTRestAPI().getJWTToken(getRequestObject());
        getBankingConfigService.enqueue(new Callback<>() {
            @Override
            public void onResponse(@NonNull retrofit2.Call<JWTTokenResponse> call, @NonNull Response<JWTTokenResponse> response) {

                if (response.isSuccessful()) {
                    JWTTokenResponse jwtTokenResponse = response.body();
                    if (jwtTokenResponse != null) {
                        String jwt = jwtTokenResponse.getJwt();
                        sharedPreferences.edit().putString(JWT_TOKEN, jwt).apply();

                        //Initiating bot connection once connected callbacks will be fired on respective actions
                        botClient.connectAsAnonymousUser(jwt, SDKConfiguration.Client.bot_name, SDKConfiguration.Client.bot_id, socketConnectionListener, SDKConfiguration.Client.isReconnect);
                    } else channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("Error_STS", "STS call failed")));
                } else {
                    channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("Error_STS", "STS call failed")));
                }
            }

            @Override
            public void onFailure(@NonNull Call<JWTTokenResponse> call, @NonNull Throwable t) {
                LogUtils.e("token refresh", t.getMessage());
                channel.invokeMethod("Callbacks", gson.toJson(new CallBackEventModel("Error_STS", "STS call failed")));
            }
        });
    }

    private void getSearchAuthorisationToken() {
        retrofit2.Call<RetailTokenResponse> getBankingConfigService = BotJWTRestBuilder.getRetailJWTRestAPI().getRetailJWTToken(SDKConfiguration.Client.stage, getAccessToken(SDKConfiguration.Client.bot_id));
        getBankingConfigService.enqueue(new Callback<>() {
            @Override
            public void onResponse(@NonNull retrofit2.Call<RetailTokenResponse> call, @NonNull Response<RetailTokenResponse> response) {

                if (response.isSuccessful()) {
                    RetailTokenResponse jwtTokenResponse = response.body();
                    if (jwtTokenResponse != null) {
                        String jwt = jwtTokenResponse.getAccessToken();
                        sharedPreferences.edit().putString(RETAIL_JWT_TOKEN, jwt).apply();
                    } else {
                        channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
                    }
                } else {
                    channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
                }
            }

            @Override
            public void onFailure(@NonNull Call<RetailTokenResponse> call, @NonNull Throwable t) {
                LogUtils.e("token refresh", t.getMessage());
                channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
            }
        });
    }

    private void getSearchResults(String searchQuery) {
        retrofit2.Call<ResponseBody> getBankingConfigService = BotJWTRestBuilder.getRetailJWTRestAPI().getSearchClassify(SDKConfiguration.Client.stage, "Bearer " + sharedPreferences.getString(RETAIL_JWT_TOKEN, ""), getClassifyObject(searchQuery, null));
        getBankingConfigService.enqueue(new Callback<>() {
            @Override
            public void onResponse(@NonNull retrofit2.Call<ResponseBody> call, @NonNull Response<ResponseBody> response) {

                if (response.isSuccessful() && response.body() != null) {
                    getProcessResults();
                } else {
                    channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
                }
            }

            @Override
            public void onFailure(@NonNull Call<ResponseBody> call, @NonNull Throwable t) {
                channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
            }
        });
    }

    private void getSearchResults(String searchQuery, HashMap<String, Object> contextData) {
        retrofit2.Call<ResponseBody> getBankingConfigService = BotJWTRestBuilder.getRetailJWTRestAPI().getSearchClassify(SDKConfiguration.Client.stage, "Bearer " + sharedPreferences.getString(RETAIL_JWT_TOKEN, ""), getClassifyObject(searchQuery, contextData));
        getBankingConfigService.enqueue(new Callback<>() {
            @Override
            public void onResponse(@NonNull retrofit2.Call<ResponseBody> call, @NonNull Response<ResponseBody> response) {

                if (response.isSuccessful() && response.body() != null) {
                    getProcessResults();
                } else {
                    channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
                }
            }

            @Override
            public void onFailure(@NonNull Call<ResponseBody> call, @NonNull Throwable t) {
                channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
            }
        });
    }

    void getProcessResults() {
        retrofit2.Call<ResponseBody> getBankingConfigService = BotJWTRestBuilder.getRetailJWTRestAPI().getProcessSearch(SDKConfiguration.Client.stage, "Bearer " + sharedPreferences.getString(RETAIL_JWT_TOKEN, ""), getProcessObject());
        getBankingConfigService.enqueue(new Callback<>() {
            @Override
            public void onResponse(@NonNull retrofit2.Call<ResponseBody> call, @NonNull Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    try {
                        if (response.body() != null) channel.invokeMethod("Callbacks", new Gson().toJson(response.body().string()));
                        else channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
                    } catch (IOException e) {
                        channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
                        throw new RuntimeException(e);
                    }
                } else {
                    channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
                }
            }

            @Override
            public void onFailure(@NonNull Call<ResponseBody> call, @NonNull Throwable t) {
                channel.invokeMethod("Callbacks", "No Search can be performed on the query provided.");
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

    private HashMap<String, Object> getAccessToken(String botId) {
        HashMap<String, Object> hsh = new HashMap<>();
        hsh.put("botId", botId);
        return hsh;
    }

    private HashMap<String, Object> getClassifyObject(String query, HashMap<String, Object> contextData) {
        HashMap<String, Object> hsh = new HashMap<>();
        if (contextData != null) hsh.put("query", SDKConfiguration.getQuery(query, contextData));
        else hsh.put("query", query);
        hsh.put("sessionId", sharedPreferences.getString(RETAIL_JWT_TOKEN, SDKConfiguration.Client.bot_id));
        hsh.put("indexName", SDKConfiguration.Client.indexName);
        hsh.put("namespace", SDKConfiguration.Client.namespace);
        return hsh;
    }

    private HashMap<String, Object> getProcessObject() {
        HashMap<String, Object> hsh = new HashMap<>();
        hsh.put("sessionId", sharedPreferences.getString(RETAIL_JWT_TOKEN, SDKConfiguration.Client.bot_id));
        hsh.put("indexName", SDKConfiguration.Client.indexName);
        hsh.put("namespace", SDKConfiguration.Client.namespace);
        hsh.put("metaFilterKeys", SDKConfiguration.Client.metaFilterKeys);
        hsh.put("metaOptions", SDKConfiguration.getMetaOptions());
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

    private boolean isOnline() {
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo netInfo = cm.getActiveNetworkInfo();
        return netInfo != null && netInfo.isConnectedOrConnecting();
    }
}
