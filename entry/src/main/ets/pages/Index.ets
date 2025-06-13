/*
* Copyright (c) 2024 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { CommonConstants } from '../constants/CommonConstants';
import { Logger } from '../utils/Logger';
import { Home } from '../view/Home';
import { window } from '@kit.ArkUI';
import { DevicesUtil } from '../utils/DevicesUtil';
import databaseManager from '../database/DatabaseManager';

const TAG = '[IndexPage]'

@Entry
@Component
struct Index {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;
  @State status: boolean = true;
  @State statusHeight: number = 0 //状态栏高度
  @State bottomAvoidAreaHeight: number = 0 //手机底部规避区域高度
  @State windowClass: window.Window | null = null //窗口管理器

  aboutToAppear(): void {
    this.init()
  }

  onPageShow(): void {
    this.windowClass?.setWindowLayoutFullScreen(true)
  }

  //初始化
  init() {
    databaseManager.init()
    window.getLastWindow(getContext(this), (err, windowClass) => {
      if (!err.code) {
        //保存窗口管理器
        this.windowClass = windowClass
        //获取状态栏高度
        this.statusHeight = px2vp(windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height)
        //获取手机底部规避区域高度
        this.bottomAvoidAreaHeight =
          px2vp(windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
            .bottomRect
            .height)
        windowClass.setWindowLayoutFullScreen(true)
        DevicesUtil.statusBarHeight = this.statusHeight
      }
    })
  }

  build() {
    GridRow({
      columns: {
        sm: BreakpointConstants.GRID_ROW_COLUMNS[0],
        md: BreakpointConstants.GRID_ROW_COLUMNS[1],
        lg: BreakpointConstants.GRID_ROW_COLUMNS[2]
      }
    }) {
      GridCol({
        span: {
          sm: BreakpointConstants.GRID_COLUMN_SPANS[0],
          md: BreakpointConstants.GRID_COLUMN_SPANS[1],
          lg: BreakpointConstants.GRID_COLUMN_SPANS[4]
        }
      }) {
        Home().padding({bottom: this.bottomAvoidAreaHeight})
      }
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT)
    }
    .onBreakpointChange((breakPoint) => {
      this.currentBreakpoint = breakPoint;
      Logger.info(TAG, `breakPoint: ${breakPoint}`)
    })
  }
}