package kore.botssdk.websocket;

import android.content.Context;
import android.os.Handler;

import java.net.URISyntaxException;
import java.util.HashMap;

import io.reactivex.Observable;
import io.reactivex.ObservableEmitter;
import io.reactivex.ObservableOnSubscribe;
import io.reactivex.Observer;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.disposables.Disposable;
import io.reactivex.schedulers.Schedulers;
import kore.botssdk.event.KoreEventCenter;
import kore.botssdk.event.RTMConnectionEvent;
import kore.botssdk.io.crossbar.autobahn.websocket.WebSocketConnection;
import kore.botssdk.io.crossbar.autobahn.websocket.WebSocketConnectionHandler;
import kore.botssdk.io.crossbar.autobahn.websocket.exceptions.WebSocketException;
import kore.botssdk.io.crossbar.autobahn.websocket.interfaces.IWebSocket;
import kore.botssdk.models.BotInfoModel;
import kore.botssdk.models.BotSocketOptions;
import kore.botssdk.models.CallBackEventModel;
import kore.botssdk.net.BotRestBuilder;
import kore.botssdk.net.RestResponse;
import kore.botssdk.utils.Constants;
import kore.botssdk.utils.LogUtils;
import retrofit2.Call;
import retrofit2.Response;


/**
 * Copyright (c) 2014 Kore Inc. All rights reserved.
 */
@SuppressWarnings("UnKnownNullness")
public final class SocketWrapper {
    private final String LOG_TAG = "SocketWrapper";
    public static SocketWrapper pKorePresenceInstance;
    SocketConnectionListener socketConnectionListener = null;
    private final IWebSocket mConnection = new WebSocketConnection();
    boolean mIsReconnectionAttemptNeeded = true;
    boolean isConnecting = false;
    HashMap<String, Object> optParameterBotInfo;
    private String accessToken;
    private String userAccessToken = null;
    String JWTToken;
    String auth;
    String botUserId;

    public BotInfoModel getBotInfoModel() {
        return botInfoModel;
    }

    public void setBotInfoModel(BotInfoModel botInfoModel) {
        this.botInfoModel = botInfoModel;
    }

    BotInfoModel botInfoModel;
    private BotSocketOptions options;

    private final Context mContext;
    /**
     * initial reconnection delay 1 Sec
     */
    int mReconnectDelay = 1000;

    /**
     * initial reconnection count
     */
    int mReconnectionCount = 0;

    /**
     * Restricting outside object creation
     */
    private SocketWrapper(Context mContext) {
        this.mContext = mContext;
    }

    public String getAccessToken() {
        return auth;
    }

    /**
     * The global default SocketWrapper instance
     */
    public static SocketWrapper getInstance(Context mContext) {
        if (pKorePresenceInstance == null) {
            pKorePresenceInstance = new SocketWrapper(mContext);
        }
        return pKorePresenceInstance;
    }

    /*
     * To prevent cloning
     * @return
     * @throws CloneNotSupportedException
     */
    @Override
    protected Object clone() throws CloneNotSupportedException {
        return new CloneNotSupportedException("Clone not supported");
    }

    private Observable<RestResponse.RTMUrl> getRtmUrlForConnectAnonymous(final String sJwtGrant, final BotInfoModel botInfoModel) {

        return Observable.create(new ObservableOnSubscribe<RestResponse.RTMUrl>() {
            @Override
            public void subscribe(ObservableEmitter<RestResponse.RTMUrl> observableEmitter) throws Exception {
                try {
                    HashMap<String, Object> hsh = new HashMap<>();
                    hsh.put(Constants.KEY_ASSERTION, sJwtGrant);
                    hsh.put(Constants.BOT_INFO, botInfoModel);

                    Call<RestResponse.BotAuthorization> botAuthorizationCall = BotRestBuilder.getBotRestService().jwtGrant(hsh);
                    Response<RestResponse.BotAuthorization> botAuthorizationResponse = botAuthorizationCall.execute();

                    HashMap<String, Object> hsh1 = new HashMap<>();
                    hsh1.put(Constants.BOT_INFO, botInfoModel);

                    if (botAuthorizationResponse.body() != null) {
                        botUserId = botAuthorizationResponse.body().getUserInfo().getUserId();
                        auth = botAuthorizationResponse.body().getAuthorization().getAccessToken();

                        Call<RestResponse.RTMUrl> rtmUrlCall = BotRestBuilder.getBotRestService().getRtmUrl("bearer " + botAuthorizationResponse.body().getAuthorization().getAccessToken(), hsh1);
                        Response<RestResponse.RTMUrl> rtmUrlResponse = rtmUrlCall.execute();

                        if (rtmUrlResponse.body() != null) {
                            observableEmitter.onNext(rtmUrlResponse.body());
                            observableEmitter.onComplete();
                        } else {
                            KoreEventCenter.post(new CallBackEventModel("Error_RTMStart", "RTM start call failed"));
                        }
                    } else {
                        KoreEventCenter.post(new CallBackEventModel("Error_JwtGrant", "JwtGrant call failed"));
                    }
                } catch (Exception e) {
                    observableEmitter.onError(e);
                }
            }
        });
    }


    /**
     * Method to invoke connection for anonymous
     * These keys are generated from bot admin console
     */
    public void connectAnonymous(final String sJwtGrant, final BotInfoModel botInfoModel, final SocketConnectionListener socketConnectionListener, BotSocketOptions options, boolean isReconnect) {
        this.socketConnectionListener = socketConnectionListener;
        this.accessToken = null;
        this.JWTToken = sJwtGrant;
        this.botInfoModel = botInfoModel;
        this.options = options;

        getRtmUrlForConnectAnonymous(sJwtGrant, botInfoModel).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread()).subscribe(new Observer<RestResponse.RTMUrl>() {
            @Override
            public void onSubscribe(Disposable disposable) {
                LogUtils.d("HI", "on Subscribe");
            }

            @Override
            public void onNext(RestResponse.RTMUrl rtmUrl) {
                try {
                    if (isReconnect) {
                        connectToSocket(rtmUrl.getUrl().concat("&isReconnect=true"), true);
                    } else {
                        connectToSocket(rtmUrl.getUrl().concat("&isReconnect=false"), false);
                    }
                } catch (URISyntaxException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onError(Throwable throwable) {
                mIsReconnectionAttemptNeeded = true;
                reconnectAttempt();
            }

            @Override
            public void onComplete() {
            }
        });
    }

    /*
     * To connect through socket
     * @param url : to connect the socket to
     * @throws URISyntaxException
     */
    void connectToSocket(String url, final boolean isReconnectionAttempt) throws URISyntaxException {
        if ((isConnecting || isConnected())) return;
        isConnecting = true;
        if (url != null) {
            if (options != null) {
                url = options.replaceOptions(url, options);
            }

            try {
                mConnection.connect(url, new WebSocketConnectionHandler() {
                    @Override
                    public void onOpen() {
                        if (socketConnectionListener != null) {
                            socketConnectionListener.onOpen(isReconnectionAttempt);
                        } else {
                            LogUtils.d("IKIDO", "Hey listener is null");
                        }
                        isConnecting = false;
                        mReconnectionCount = 1;
                        mReconnectDelay = 1000;
                        KoreEventCenter.post(new RTMConnectionEvent(true));
                    }

                    @Override
                    public void onClose(int code, String reason) {
                        LogUtils.d(LOG_TAG, "Connection Lost.");
                        if (socketConnectionListener != null) {
                            socketConnectionListener.onClose(code, reason);
                        } else {
                            LogUtils.d("IKIDO", "Hey listener is null");
                        }

                        isConnecting = false;
                        reconnectAttempt();
                    }

                    @Override
                    public void onMessage(String payload) {
                        if (socketConnectionListener != null) {
                            socketConnectionListener.onTextMessage(payload);
                        } else {
                            LogUtils.d("IKIDO", "Hey listener is null");
                        }
                    }
                });
            } catch (WebSocketException e) {
                isConnecting = false;
                if (e.getMessage() != null && e.getMessage().equals("already connected")) {
                    if (socketConnectionListener != null) {
                        socketConnectionListener.onOpen(isReconnectionAttempt);
                    }
                    mReconnectionCount = 1;
                    mReconnectDelay = 1000;
                }
                e.printStackTrace();
            }
        }
    }

    /**
     * Reconnect to socket
     */
    void reconnect() {
        if (accessToken != null) {
            //Reconnection for valid credential
            reconnectForAuthenticUser();
        } else {
            //Reconnection for anonymous
            reconnectForAnonymousUser();
        }
    }

    private Observable<RestResponse.RTMUrl> getRtmUrlReconnectForAuthenticUser(String accessToken) {

        return Observable.create(new ObservableOnSubscribe<RestResponse.RTMUrl>() {
            @Override
            public void subscribe(ObservableEmitter<RestResponse.RTMUrl> observableEmitter) throws Exception {
                try {
                    Call<RestResponse.JWTTokenResponse> jwtTokenResponseCall = BotRestBuilder.getBotRestService().getJWTToken("bearer " + accessToken);
                    Response<RestResponse.JWTTokenResponse> jwtTokenResponseResponse = jwtTokenResponseCall.execute();
                    if (jwtTokenResponseResponse.body() != null) {
                        HashMap<String, Object> hsh = new HashMap<>(1);
                        hsh.put(Constants.KEY_ASSERTION, jwtTokenResponseResponse.body().getJwt());

                        Call<RestResponse.BotAuthorization> botAuthorizationCall = BotRestBuilder.getBotRestService().jwtGrant(hsh);
                        Response<RestResponse.BotAuthorization> botAuthorizationResponse = botAuthorizationCall.execute();

                        if (botAuthorizationResponse.body() != null) {
                            Call<RestResponse.RTMUrl> rtmUrlCall = BotRestBuilder.getBotRestService().getRtmUrl("bearer " + botAuthorizationResponse.body().getAuthorization().getAccessToken(), optParameterBotInfo, true);
                            Response<RestResponse.RTMUrl> rtmUrlResponse = rtmUrlCall.execute();
                            observableEmitter.onNext(rtmUrlResponse.body());
                        }
                    }
                    observableEmitter.onComplete();
                } catch (Exception e) {
                    observableEmitter.onError(e);
                }
            }
        });
    }

    /**
     * Reconnection for authentic user
     */
    private void reconnectForAuthenticUser() {
        LogUtils.i(LOG_TAG, "Connection lost. Reconnecting....");

        getRtmUrlReconnectForAuthenticUser(accessToken).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread()).subscribe(new Observer<RestResponse.RTMUrl>() {
            @Override
            public void onSubscribe(Disposable disposable) {
            }

            @Override
            public void onNext(RestResponse.RTMUrl rtmUrl) {
                try {
                    connectToSocket(rtmUrl.getUrl().concat("&isReconnect=true"), true);
                } catch (URISyntaxException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onError(Throwable throwable) {
            }

            @Override
            public void onComplete() {
            }
        });


    }

    private Observable<RestResponse.RTMUrl> getRtmUrlReconnectForAnonymousUser() {

        return Observable.create(new ObservableOnSubscribe<RestResponse.RTMUrl>() {
            @Override
            public void subscribe(ObservableEmitter<RestResponse.RTMUrl> observableEmitter) throws Exception {
                try {
                    HashMap<String, Object> hsh = new HashMap<>();
                    hsh.put(Constants.KEY_ASSERTION, JWTToken);
                    hsh.put(Constants.BOT_INFO, botInfoModel);

                    Call<RestResponse.BotAuthorization> botAuthorizationCall = BotRestBuilder.getBotRestService().jwtGrant(hsh);
                    Response<RestResponse.BotAuthorization> botAuthorizationResponse = botAuthorizationCall.execute();
                    HashMap<String, Object> hsh1 = new HashMap<>();
                    hsh1.put(Constants.BOT_INFO, botInfoModel);

                    if (botAuthorizationResponse.body() != null) {
                        auth = botAuthorizationResponse.body().getAuthorization().getAccessToken();
                        botUserId = botAuthorizationResponse.body().getUserInfo().getUserId();

                        Call<RestResponse.RTMUrl> rtmUrlCall = BotRestBuilder.getBotRestService().getRtmUrl("bearer " + botAuthorizationResponse.body().getAuthorization().getAccessToken(), hsh1, true);
                        Response<RestResponse.RTMUrl> rtmUrlResponse = rtmUrlCall.execute();

                        if (rtmUrlResponse.body() != null) {
                            observableEmitter.onNext(rtmUrlResponse.body());
                            observableEmitter.onComplete();
                        } else {
                            KoreEventCenter.post(new CallBackEventModel("Error_RTMStart", "RTM start call failed"));
                        }
                    } else {
                        KoreEventCenter.post(new CallBackEventModel("Error_JwtGrant", "JwtGrant call failed"));
                    }

                } catch (Exception e) {
                    observableEmitter.onError(e);
                }
            }

        });
    }

    /**
     * Reconnection for anonymous user
     */
    private void reconnectForAnonymousUser() {

        LogUtils.i(LOG_TAG, "Connection lost. Reconnecting....");

        getRtmUrlReconnectForAnonymousUser().subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread()).subscribe(new Observer<RestResponse.RTMUrl>() {
            @Override
            public void onSubscribe(Disposable disposable) {
            }

            @Override
            public void onNext(RestResponse.RTMUrl rtmUrl) {
                try {
                    connectToSocket(rtmUrl.getUrl().concat("&isReconnect=true"), true);
                } catch (URISyntaxException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onError(Throwable throwable) {
                mIsReconnectionAttemptNeeded = true;
                reconnectAttempt();
            }

            @Override
            public void onComplete() {
            }
        });

    }

    /*
     * @param msg : The message object
     */
    public void sendMessage(String msg) {
        if (mConnection.isConnected()) {
            mConnection.sendMessage(msg);
        } else {
            if (userAccessToken != null && socketConnectionListener != null) {
                socketConnectionListener.refreshJwtToken();
            } else {
                reconnect();
            }
            LogUtils.e(LOG_TAG, "Connection is not present. Reconnecting...");
        }
    }

    /*
     * Method to Reconnection attempt based on incremental delay
     *
     * @return
     */
    /*
     * Method to Reconnection attempt based on incremental delay
     *
     * @return
     */
    void reconnectAttempt() {
        if (mReconnectionCount < 5) {
            mReconnectDelay = getReconnectDelay();
            try {
                final Handler _handler = new Handler();
                Runnable r = new Runnable() {
                    @Override
                    public void run() {
                        LogUtils.d(LOG_TAG, "Entered into reconnection post delayed " + mReconnectDelay);
                        if (mIsReconnectionAttemptNeeded && !isConnected()) {
                            reconnect();
                            LogUtils.d(LOG_TAG, "#### trying to reconnect");
                        }

                    }
                };
                _handler.postDelayed(r, mReconnectDelay);
            } catch (Exception e) {
                LogUtils.d(LOG_TAG, ":: The Exception is " + e);
            }
        } else {
            socketConnectionListener.onReconnectStopped("Reconnection Stopped");
        }
    }

    /*
     * The reconnection attempt delay(incremental delay)
     * @return
     */
    int getReconnectDelay() {
        mReconnectionCount++;
        LogUtils.d(LOG_TAG, "Reconnection count " + mReconnectionCount);

        return 5 * 1000;
    }

    /**
     * For disconnecting user's presence
     * Call this method when the user logged out
     */
    public void disConnect() {
        mIsReconnectionAttemptNeeded = false;
        if (mConnection.isConnected()) {
            try {
                mConnection.sendClose();
            } catch (Exception e) {
                LogUtils.d(LOG_TAG, "Exception while disconnection");
            }
            LogUtils.d(LOG_TAG, "DisConnected successfully");
        } else {
            LogUtils.d(LOG_TAG, "Cannot disconnect.._client is null");
        }


        //The bot URL may change
        BotRestBuilder.clearInstance();
        auth = null;
        botUserId = null;
    }

    /*
     * To determine wither socket is connected or not
     *
     * @return boolean indicating the connection presence.
     */
    public boolean isConnected() {
        return mConnection.isConnected();
    }

}