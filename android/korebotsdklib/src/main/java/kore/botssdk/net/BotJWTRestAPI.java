package kore.botssdk.net;

import java.util.HashMap;

import kore.botssdk.models.JWTTokenResponse;
import kore.botssdk.models.RetailTokenResponse;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.Header;
import retrofit2.http.Headers;
import retrofit2.http.POST;

@SuppressWarnings("UnKnownNullness")
public interface BotJWTRestAPI {
    String URL_VERSION = "/1.1";
    @Headers({
            "alg:RS256",
            "typ:JWT"
    })
    //@POST("/api/users/sts")
    @POST("users/sts")
    Call<JWTTokenResponse> getJWTToken(@Body HashMap<String, Object> jsonObject);
    //@POST("/api/users/sts")
    @POST("auth/token")
    Call<RetailTokenResponse> getRetailJWTToken(@Header("stage") String stage, @Body HashMap<String, Object> jsonObject);

    // Get JWT Token
    @POST("/api" + URL_VERSION + "/users/jwttoken")
    Call<JWTTokenResponse> getJWTToken(@Header("Authorization") String token, @Body HashMap<String, Object> body);

    // Get JWT Token
    @POST("/api/users/sts")
    Call<JWTTokenResponse> getJWTToken(@Header("Authorization") String token);

}
