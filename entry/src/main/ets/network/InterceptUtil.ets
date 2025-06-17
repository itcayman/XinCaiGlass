import { http } from "@kit.NetworkKit";

export interface HttpInterceptor {
  intercept: (options: http.HttpRequestOptions) => http.HttpRequestOptions
}

export class DefaultHeadersInterceptor implements HttpInterceptor {
  intercept(options: http.HttpRequestOptions) {
    let headers: Record<string, string> = options.header as Record<string, string>
    headers.test1 = 'test'
    return options
  }
}

export interface HttpResponseInterceptor {
  intercept: (data: http.HttpResponse) => http.HttpResponse
}

export class DefaultResponseInterceptor implements HttpResponseInterceptor {
  intercept(data: http.HttpResponse){
    // 对 data 进行错误类型统一处理
    return data
  }
}

