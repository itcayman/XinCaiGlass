import { TeleprompterEntity } from '../database/bean/TeleprompterEntity';
import databaseManager from '../database/DatabaseManager';
import { Logger } from '../utils/Logger';
import { CreateTeleprompterView } from '../view/CreateTeleprompterView';
import { CustomNavigationBar } from '../view/CustomNavigationBar';
import { NewTeleprompterNavigationBar } from '../view/NewTeleprompterNavigationBar';
import { emitter, systemDateTime } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';
import { TELEPROMPTER_ADD_SUCCESS } from '../utils/EventIds';

const TAG: string = '[Page][TeleprompterEdit]'

@Entry
@Component
struct TeleprompterEditPage {
  @State title: string = '';
  @State content: string = ''
  private callback: Callback<void> = () => {
    Logger.debug(TAG, 'done click! content:' + this.content)
    let data = new TeleprompterEntity(0, this.title, this.content, systemDateTime.getTime());
    databaseManager.insertTeleprompter(data,() => {
      Logger.debug(TAG, `成功插入提词器内容, id=${data.id}, title=${data.title}, timestamp=${data.timestamp}`);
      let eventData: emitter.EventData = { data: { Teleprompter: data } }
      emitter.emit({ eventId: TELEPROMPTER_ADD_SUCCESS, priority: emitter.EventPriority.HIGH }, eventData);
      router.back()
    })
  }

  build() {
    Column() {
      // 使用自定义导航栏组件
      NewTeleprompterNavigationBar({ parBGColor: Color.White, callback: this.callback })
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top }
        })

      CreateTeleprompterView({ title: $title, content: $content })
        .margin({
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