@Entry
@Component
struct TextTypesetExample {
  @State text: string = "这是一个示例文本，用于演示onTypesetEnd事件的使用。\n鸿蒙当前在text上没有提供可以直接获取字符索引在第几行，不过当前layoutManger接口中已有供开发者自行实现的能力。getLineMetrics可以获取指定行的行信息、文本样式信息、以及字体属性信息，其中就包含了行的开始结束的索引位。通过getLineMetrics获取每行的索引范围比较即可获取我们想要某索引位所在的具体行数了，下面分享实现的小demo供大家参考：";
  @State lines: Array<string> = [];
  controller: TextController = new TextController();

  build() {
    Column() {
      Text(this.text, { controller: this.controller })
        .fontSize(20)
        .width('90%')
        .onAreaChange(() => {
          let layoutManager: LayoutManager = this.controller.getLayoutManager();
          let lineCount =  layoutManager.getLineCount();
          console.log('@tc', 'lineCount: '+lineCount);
          for (let index = 0; index < lineCount; index++) {
            let metrics = layoutManager.getLineMetrics(index)
            console.log('@tc', 'line: '+index+", range:"+metrics.startIndex+"-"+metrics.endIndex+"\n"+
            this.text.substring(metrics.startIndex, metrics.endIndex));
          }
        })
    }
    .width('100%').margin({top : 50})
  }
}