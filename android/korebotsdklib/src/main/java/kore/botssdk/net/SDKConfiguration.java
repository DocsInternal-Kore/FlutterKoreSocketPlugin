package kore.botssdk.net;

/*
 * Copyright (c) 2014 Kore Inc. All rights reserved.
 */

import android.annotation.SuppressLint;
import android.util.Log;
import android.view.View;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * This class is for defining properties
 */
@SuppressLint("UnknownNullness")
public class SDKConfiguration {

    public static final String APP_REQ_COLOR = "#3942f6"; // KORA COLOR "#3942f6" // BMC COLOR 2f91e5
    /**
     * bot init text  and related settings
     */
    private static boolean TRIGGER_INIT_MESSAGE = false;
    private static String INIT_MESSAGE = "Welpro";
    private static boolean TIME_STAMPS_REQUIRED = true;
    private static final boolean APPLY_FONT_STYLE = true;
    protected static HashMap<String, View> hsh = new HashMap<>();

    public static boolean isTriggerInitMessage() {
        return TRIGGER_INIT_MESSAGE;
    }

    public static void setTriggerInitMessage(boolean triggerInitMessage) {
        TRIGGER_INIT_MESSAGE = triggerInitMessage;
    }

    public static String getInitMessage() {
        return INIT_MESSAGE;
    }

    public static void setInitMessage(String initMessage) {
        INIT_MESSAGE = initMessage;
    }


    public static boolean isApplyFontStyle() {
        return APPLY_FONT_STYLE;
    }

    //JWTServer related configurations
    public static class JWTServer {
        static String JWT_SERVER_URL = "https://mk2r2rmj21.execute-api.us-east-1.amazonaws.com/dev/";

        static String jwt_token = "";

        public static void setJwt_token(String jwt_token) {
            JWTServer.jwt_token = jwt_token;
        }

        public static String getJwt_token() {
            return jwt_token;
        }

    }

    public static void setJwtServerUrl(String serverUrl) {
        JWTServer.JWT_SERVER_URL = serverUrl;
    }

    //Server related configurations
    public static class Server {

        public static void setKoreBotServerUrl(String koreBotServerUrl) {
            KORE_BOT_SERVER_URL = koreBotServerUrl;
        }

        public static void setServerUrl(String serverUrl) {
            SERVER_URL = serverUrl;
        }

        public static String KORE_BOT_SERVER_URL = "https://bots.kore.ai/";//https://qa-bots.kore.ai";
        public static final String TTS_WS_URL = "wss://speech.kore.ai/tts/ws";
        public static final boolean IS_ANONYMOUS_USER = false;
        public static String SERVER_URL = "https://bots.kore.ai/"; // "https://demo.kore.net";
        public static String RETAIL_SERVER_URL = "https://bots.kore.ai/"; // "https://demo.kore.net";
        public static final String Branding_SERVER_URL = "https://bots.kore.ai/";
        public static final String koreAPIUrl = "https://sit-bots.kore.ai/";
        public static RestResponse.BotCustomData customData = new RestResponse.BotCustomData();
        public static void setCustomData(RestResponse.BotCustomData customData) {
            Server.customData = customData;
        }
    }

    public static class Client {
        //SDK 2.0
        public static String client_id = "";
        public static String client_secret = "";
        public static String identity = "";
        public static String bot_name = "";
        public static String bot_id = "";
        public static String indexName = "";
        public static String[] metaFilterKeys = {"gender", "price", "description"};
        public static String namespace = "";
        public static final String tenant_id = "605da1dbb5f6f00badadb665";
        public static final boolean enablePanel = false;
        public static boolean isReconnect = false;
        public static final boolean enable_ack_delivery = false;
        public static final boolean isWebHook = false;
        public static final String webHook_client_id = "cs-ab324147-4c82-5eb5-b73e-42cf8d8340f8";//"cs-96c4747a-bb79-58b0-9dca-0dcf6c6148cf";//"cs-dc0f84ac-4751-5293-b254-6a0a382ab08c";//"cs-a269ad0a-45ec-5b41-9950-18571e42a6a4";//"cs-5649368e-68bb-555a-8803-935f223db585";
        public static final String webHook_client_secret = "kD9HrB5CPeneebDZFXpRmUxamx55NfVsx0t4nVr78v8=";//"qc4c+FOpEo88m27BgECpcS/oC/CKDWa8u70ll0qr4MM=";//"MiFzNLLWTQZddj1HOmdM4iyePhQ+gED4jdUg88Ujh1Y=";//"kmZ7ck9wRxSVV2dNNwi2P3UZI3qacJgu7JL9AmZapS4=";//"AHSubkG09DRdcz9xlzxUXfrxyRx9V0Yhd+6SnXtjYe4=";
        public static final String webHook_identity = "sudheer.jampana@kore.com";
        public static final String webHook_bot_id = "st-fd0f5024-2318-56fe-8354-555e1786133e";//"st-2e4c9eaf-070c-5b86-8020-add76f37e3a2";//"st-05303785-9992-526c-a83c-be3252fd478e";//"st-caecd28f-64ed-5224-a612-7a3d3a870aed";//"st-cc32974e-c7a2-52d1-83bf-c3dc2b2a9db3";

        //Weebhook
        // for webhook based communication use following option
        public static String webhookURL = "https://qa1-bots.kore.ai/chatbot/v2/webhook/st-ea1b128f-7895-581a-8c87-bbfe3b9f1ff1";
        public static int apiVersion = 2;
        public static String stage = "dev";
        //webhookURL:'https://qa-bots.kore.ai/chatbot/v2/webhook/st-5840c71a-ec0b-516e-8d9a-f9e608ea8c4b',
        //webhookURL:'https://qa-bots.kore.ai/chatbot/hooks/st-5840c71a-ec0b-516e-8d9a-f9e608ea8c4b/hookInstance/ivrInst-62c362b9-5f88-5ec5-9f3f-7c0eb9801e70'
        //webhookURL:'https://qa-bots.kore.ai/chatbot/v2/webhook/st-5840c71a-ec0b-516e-8d9a-f9e608ea8c4b/hookInstance/ivrInst-62c362b9-5f88-5ec5-9f3f-7c0eb9801e70'
    }

    public static class BubbleColors {
        public static String rightBubbleSelected = APP_REQ_COLOR;

        public static void setRightBubbleSelected(String rightBubbleSelected) {
            BubbleColors.rightBubbleSelected = rightBubbleSelected;
        }

        public static void setRightBubbleUnSelected(String rightBubbleUnSelected) {
            BubbleColors.rightBubbleUnSelected = rightBubbleUnSelected;
        }

        public static void setLeftBubbleSelected(String leftBubbleSelected) {
            BubbleColors.leftBubbleSelected = leftBubbleSelected;
        }

        public static void setLeftBubbleUnSelected(String leftBubbleUnSelected) {
            BubbleColors.leftBubbleUnSelected = leftBubbleUnSelected;
        }

        public static void setLeftBubbleTextColor(String leftBubbleTextColor) {
            BubbleColors.leftBubbleTextColor = leftBubbleTextColor;
        }

        public static void setRightBubbleTextColor(String rightBubbleTextColor) {
            BubbleColors.rightBubbleTextColor = rightBubbleTextColor;
        }

        public static void setWhiteColor(String whiteColor) {
            BubbleColors.whiteColor = whiteColor;
        }

        public static void setLeftBubbleBorderColor(String leftBubbleBorderColor) {
            BubbleColors.leftBubbleBorderColor = leftBubbleBorderColor;
        }

        public static void setRightLinkColor(String rightLinkColor) {
            BubbleColors.rightLinkColor = rightLinkColor;
        }

        public static void setLeftLinkColor(String leftLinkColor) {
            BubbleColors.leftLinkColor = leftLinkColor;
        }


        public static String rightBubbleUnSelected = APP_REQ_COLOR;
        public static String leftBubbleSelected = "#D3D3D3";
        public static String leftBubbleUnSelected = "#f8f9f8";
        public static String leftBubbleTextColor = "#404051";
        public static String rightBubbleTextColor = "#161628";//"#757587";
        public static String whiteColor = "#FFFFFF";
        public static String leftBubbleBorderColor = "#eeeef2";
        public static String rightLinkColor = APP_REQ_COLOR;
        public static String leftLinkColor = APP_REQ_COLOR;
        public static final boolean BubbleUI = false;
        public static final boolean showIcon = false;

        public static int getIcon() {
            return icon;
        }

        public static void setIcon(int icon) {
            BubbleColors.icon = icon;
        }

        public static String getIcon_url() {
            return icon_url;
        }

        public static void setIcon_url(String icon_url) {
            BubbleColors.icon_url = icon_url;
        }

        private static int icon = -1;
        private static String icon_url = "";

        public static String getProfileColor() {
            return profileColor;
        }

        public static void setProfileColor(String profileColor) {
            BubbleColors.profileColor = profileColor;
        }

        static String profileColor = APP_REQ_COLOR;

        public static void setQuickReplyColor(String quickReplyColor) {
            BubbleColors.quickReplyColor = quickReplyColor;
        }

        public static String quickReplyColor = "#EEEEF0";
        public static String quickReplyTextColor = "#000000";
        public static String quickBorderColor = "#000000";

    }

    public static boolean isTimeStampsRequired() {
        return TIME_STAMPS_REQUIRED;
    }

    public static void setTimeStampsRequired(boolean timeStampsRequired) {
        TIME_STAMPS_REQUIRED = timeStampsRequired;
    }

    /**
     * don't use relative it is licenced version
     */
    public enum FONT_TYPES {
        ROBOTO, RELATIVE
    }

    private static final FONT_TYPES fontType = FONT_TYPES.ROBOTO;

    public static void setCustomTemplateView(String templateName, View templateView) {
        hsh.put(templateName, templateView);
        Log.e("HashMap Count", hsh.size() + "");
    }

    public static HashMap<String, View> getCustomTemplateView() {
        return hsh;
    }
    public static JsonArray getMetaOptions() {
        JsonArray jsonArray = new JsonArray();
        JsonObject jsonOutObject = new JsonObject();
        try
        {
            JsonObject jsonOneObject = new JsonObject();
            jsonOneObject.addProperty("operator", "arithmetic");
            JsonObject jsonTwoObject = new JsonObject();
            jsonTwoObject.addProperty("operator", "'");
            jsonOutObject.add("price", jsonOneObject);
            jsonOutObject.add("gender", jsonTwoObject);
            jsonArray.add(jsonOutObject);
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }

        return jsonArray;
    }

    public static String getQuery(String query, HashMap<String, Object> contextData)
    {
        StringBuilder queryString = new StringBuilder();
        queryString.append(query);
        queryString.append(" ");

        for (Map.Entry<String, Object> entry : contextData.entrySet()) {
            queryString.append(entry.getKey());
            queryString.append(":");
            queryString.append(entry.getValue());
            queryString.append(" ");
        }

        return queryString.toString().trim();
    }

}
