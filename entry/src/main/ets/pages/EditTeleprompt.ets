import { CreateTelepromptView } from '../view/CreateTelepromptView';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { NewTelepromptNavigationBar } from '../view/NewTelepromptNavigationBar';

@Entry
@Component
struct EditTeleprompt {
  @State title: string = '';

  build() {
    Column() {
      // 使用自定义导航栏组件
      NewTelepromptNavigationBar({ parBGColor: Color.White }).alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top }
      })

      CreateTelepromptView().margin({
        left: 10,
        right: 10,
        bottom: 10
      }).layoutWeight(1)
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}