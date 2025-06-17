export default class ResponseResult<T> {
  code: string
  msg: string | Resource
  data?: T
  constructor() {
    this.code = ''
    this.msg = ''
  }
}