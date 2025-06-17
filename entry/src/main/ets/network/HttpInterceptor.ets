import { http } from "@kit.NetworkKit"

// 拦截器接口
export interface HttpInterceptor {
  intercept: (options: http.HttpRequestOptions) => http.HttpRequestOptions
}

// 默认拦截器，可自行修改，下面提供了对请求heade修改的示例
export class DefaultHeadersInterceptor implements HttpInterceptor {
  intercept(options: http.HttpRequestOptions) {
    let headers: Record<string, string> = options.header as Record<string, string>
    headers.test1 = 'test'
    return options
  }
}