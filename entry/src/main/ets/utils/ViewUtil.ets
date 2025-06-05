import { IntentionCode } from '@kit.InputKit'
import { ViewSize } from './ViewSize'

export class ViewUtil {
  static rect_left: number
  static rect_top: number
  static rect_right: number
  static rect_bottom: number
  static rect_value: Record<string, number>

  //获取组件所占矩形区域坐标
  static getComponentRect(key: string): Record<string, number> {
    let strJson = getInspectorByKey(key)
    let obj: Record<string, string> = JSON.parse(strJson)
    console.info("[getInspectorByKey] current component obj is: " + JSON.stringify(obj))
    let rectInfo: string[] = JSON.parse('[' + obj.$rect + ']')
    console.info("[getInspectorByKey] rectInfo is: " + rectInfo)
    ViewUtil.rect_left = JSON.parse('[' + rectInfo[0] + ']')[0] // 相对于组件左上角的水平方向坐标
    ViewUtil.rect_top = JSON.parse('[' + rectInfo[0] + ']')[1] // 相对于组件左上角的垂直方向坐标
    ViewUtil.rect_right = JSON.parse('[' + rectInfo[1] + ']')[0] // 相对于组件右下角的水平方向坐标
    ViewUtil.rect_bottom = JSON.parse('[' + rectInfo[1] + ']')[1] // 相对于组件右下角的垂直方向坐标
    return ViewUtil.rect_value = {
      "left": ViewUtil.rect_left,
      "top": ViewUtil.rect_top,
      "right": ViewUtil.rect_right,
      "bottom": ViewUtil.rect_bottom
    }
  }

  //获取组件尺寸
  static getComponentSize(key: string): ViewSize {
    let strJson = getInspectorByKey(key)
    let obj: Record<string, string> = JSON.parse(strJson)
    console.info("[getInspectorByKey] current component obj is: " + JSON.stringify(obj))
    let rectInfo: string[] = JSON.parse('[' + obj.$rect + ']')
    console.info("[getInspectorByKey] rectInfo is: " + rectInfo)
    let rect_left: number = JSON.parse('[' + rectInfo[0] + ']')[0] // 相对于组件左上角的水平方向坐标
    let rect_top: number = JSON.parse('[' + rectInfo[0] + ']')[1] // 相对于组件左上角的垂直方向坐标
    let rect_right: number = JSON.parse('[' + rectInfo[1] + ']')[0] // 相对于组件右下角的水平方向坐标
    let rect_bottom: number = JSON.parse('[' + rectInfo[1] + ']')[1] // 相对于组件右下角的垂直方向坐标
    return new ViewSize(rect_right - rect_left, rect_bottom - rect_top)
  }
}