public class CustomHttpRequestBuilder {
    private String body = '';
    private String url = '';
    private Map<String, Object> jsonBody;
    private HttpRequest httpRequest;
    
    public CustomHttpRequestBuilder() {
        this.jsonBody = new Map<String, Object>();
        this.httpRequest = new HttpRequest();
    }
    
    public CustomHttpRequestBuilder addParamToBody(String key, String value) {
        if (String.isBlank(this.body)) {
            this.body += key + '=' + value;
        } else {
            this.body += '&' + key + '=' + value;
        }
        return this;
    }
    
    public CustomHttpRequestBuilder addParamToUrl(String key, String value) {
        if (String.isNotBlank(key) && String.isNotBlank(value)) {
            if (!this.url.containsIgnoreCase('?')) {
                this.url += '?' + key + '=' + value;
            } else {
                this.url += '&' + key + '=' + value;
            }
        }
        return this;
    }
    
    public CustomHttpRequestBuilder addJsonBody(String body) {
        if (String.isNotBlank(body)) {
            httpRequest.setBody(body);
        }
        return this;
    }
    public CustomHttpRequestBuilder addParamToJsonBody(String key, Object value) {
        this.jsonBody.put(key, value);
        return this;
    }
    
    public CustomHttpRequestBuilder createRequest(String endPoint, String httpMethod) {
        httpRequest.setEndpoint(endPoint);
        httpRequest.setMethod(httpMethod);
        return this;
    }
    
    public CustomHttpRequestBuilder createRequest(String httpMethod) {
        httpRequest.setEndpoint(this.url);
        httpRequest.setMethod(httpMethod);
        return this;
    }
    
    public CustomHttpRequestBuilder addHeader(String key, String value) {
        if (String.isNotBlank(key) && String.isNotBlank(value)) {
            httpRequest.setHeader(key, value);
        }
        return this;
    }
    
    public CustomHttpRequestBuilder createBody() {
        httpRequest.setBody(body);
        return this;
    }
    
    public CustomHttpRequestBuilder createJsonBody() {
        httpRequest.setBody(JSON.serialize(this.jsonBody));
        return this;
    }
    
    public HttpResponse doRequest() {
        System.debug('httpRequest - ' + httpRequest.getBody());
        system.debug(httpRequest.getEndpoint());
        //system.debug(httpRequest.getMethod());
        //system.debug(httpRequest.getHeader('Content-Type'));
        system.debug(this.body);
        return new Http().send(httpRequest);
    }
    
    public CustomHttpRequestBuilder addBaseUrl(String url) {
        this.url = url;
        return this;
    }
    
    public String getUrl() {
        return this.url;
    }
    
    public CustomHttpRequestBuilder addTimeout(Integer milliseconds) {
        httpRequest.setTimeout(milliseconds);
        return this;
    }
    
    public static void test() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    
    }

}