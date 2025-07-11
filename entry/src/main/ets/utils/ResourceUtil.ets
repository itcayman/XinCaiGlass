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

import { ConfigurationConstant } from '@kit.AbilityKit';
import { BreakpointType } from './BreakpointType';

export class ResourceUtil {
  /**
   * Page column padding.
   */
  private static pageColPadding: BreakpointType<Resource> = new BreakpointType($r('app.float.page_col_padding_sm'),
    $r('app.float.page_col_padding_md'), $r('app.float.page_col_padding_lg'));
  /**
   * Common image size list.
   */
  private static commonImgSize: Resource[] = [$r('app.float.common_image_size_1'), $r('app.float.common_image_size_2'),
    $r('app.float.common_image_size_3'), $r('app.float.common_image_size_4'), $r('app.float.common_image_size_5'),
    $r('app.float.common_image_size_6'), $r('app.float.common_image_size_7'), $r('app.float.common_image_size_8'),
    $r('app.float.common_image_size_9'), $r('app.float.common_image_size_10'), $r('app.float.common_image_size_11')];
  /**
   * Common background color list.
   */
  private static commonBackgroundColor: Resource[] = [$r('app.color.common_background_1'),
    $r('app.color.common_background_2'), $r('app.color.common_background_3')];
  /**
   * Common border color list.
   */
  private static commonBorderColorList: Resource[] = [$r('app.color.common_border_color_1'),
    $r('app.color.common_border_color_2'), $r('app.color.common_border_color_3'),
    $r('app.color.common_border_color_4')];
  /**
   * Common divider color.
   */
  private static commonDividerColor: Resource = $r('app.color.common_divider_color');
  /**
   * Common border radius list.
   */
  private static commonBorderRadius: Resource = $r('app.float.common_border_radius_3')
  /**
   * Common padding size list.
   */
  private static commonPadding: Resource[] = [
    $r("app.float.common_padding_1"), $r("app.float.common_padding_2"),
    $r('app.float.common_padding_3'), $r('app.float.common_padding_4'),
    $r('app.float.common_padding_5'), $r('app.float.common_padding_6')];
  /**
   * Common text color list.
   */
  private static commonTextColor: Resource[] =
    [$r('app.color.common_text_color_1'), $r('app.color.common_text_color_2')];
  /**
   * Common text size list.
   */
  private static commonTextSize: Resource[] = [$r('app.float.common_text_size_1'),
    $r('app.float.common_text_size_2'),
    $r('app.float.common_text_size_3')];

  static getPageColPadding(): BreakpointType<Resource> {
    return ResourceUtil.pageColPadding;
  }

  static getCommonImgSize(): Resource[] {
    return ResourceUtil.commonImgSize;
  }

  static getCommonBackgroundColor(): Resource[] {
    return ResourceUtil.commonBackgroundColor;
  }

  static getCommonBorderColor(): Resource[] {
    return ResourceUtil.commonBorderColorList;
  }

  static getCommonDividerColor(): Resource {
    return ResourceUtil.commonDividerColor;
  }

  static getCommonBorderRadius(): Resource {
    return ResourceUtil.commonBorderRadius;
  }

  static getCommonPadding(): Resource[] {
    return ResourceUtil.commonPadding;
  }

  static getCommonTextColor(): Resource[] {
    return ResourceUtil.commonTextColor;
  }

  static getCommonTextSize(): Resource[] {
    return ResourceUtil.commonTextSize;
  }

  static getLottiePath(name: string, currentMode: number): string {
    return currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
      `common/lottie/dark/${name}.json` : // 深色模式路径
      `common/lottie/light/${name}.json`; // 浅色模式路径
  }
}