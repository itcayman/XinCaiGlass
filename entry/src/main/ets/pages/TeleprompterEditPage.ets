import { TeleprompterEntity } from '../database/bean/TeleprompterEntity';
import databaseManager from '../database/DatabaseManager';
import { Logger } from '../utils/Logger';
import { CreateTeleprompterView } from '../view/CreateTeleprompterView';
import { NewTeleprompterNavigationBar } from '../view/NewTeleprompterNavigationBar';
import { emitter, systemDateTime } from '@kit.BasicServicesKit';
import { TELEPROMPTER_ADD_SUCCESS } from '../utils/EventIds';
import { router } from '@kit.ArkUI';

const TAG: string = '[Page][TeleprompterEdit]'

@Entry
@Component
struct TeleprompterEditPage {
  @State title: string = '';
  @State content: string = '';
  @State timestamp: number = 0;
  private callback: Callback<void> = () => {
    Logger.debug(TAG, 'done click! content:' + this.content)
    if (this.timestamp == 0) {
      this.timestamp = systemDateTime.getTime();
    }
    let data = new TeleprompterEntity(0, this.title, this.content, this.timestamp);
    databaseManager.insertTeleprompter(data, () => {
      Logger.debug(TAG, `成功插入提词器内容, id=${data.id}, title=${data.title}, timestamp=${data.timestamp}`);
      let eventData: emitter.EventData = { data: { Teleprompter: data } }
      emitter.emit({ eventId: TELEPROMPTER_ADD_SUCCESS, priority: emitter.EventPriority.HIGH }, eventData);
      router.back()
    })
  }

  aboutToAppear(): void {
    const params = router.getParams() as TeleprompterEntity;
    if (params === undefined) {
      return;
    }
    this.title = params.title;
    this.content = params.content;
    this.timestamp = params.timestamp
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