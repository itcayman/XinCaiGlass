import { abilityAccessCtrl, bundleManager, Context, Permissions } from '@kit.AbilityKit'
import { ArrayList } from '@kit.ArkTS'

export class PermissionUtil {
  private static readonly sUtil: PermissionUtil = new PermissionUtil()
  private mAtManager: abilityAccessCtrl.AtManager
  private mTokenId: number
  private mContext?: Context
  private mPermissions: ArrayList<Permissions> = new ArrayList()

  constructor() {
    this.mAtManager = abilityAccessCtrl.createAtManager()
    let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    this.mTokenId = bundleInfo.appInfo.accessTokenId
  }

  public static init(context: Context): PermissionUtil {
    PermissionUtil.sUtil.mContext = context
    return PermissionUtil.sUtil
  }

  public addPermissions(permission: Permissions): PermissionUtil {
    this.mPermissions.add(permission)
    return PermissionUtil.sUtil
  }


  /**
   * 检测并申请权限
   * @returns
   */
  async request() {
    return new Promise<RequestResult>((resolve, reject) => {
      //如果开发者没有添加权限则抛出异常
      if (this.mPermissions.length === 0) {
        reject(Error("请添加权限"))
        return
      }
      //克隆开发添加的权限
      let temp = this.mPermissions.clone()
      let grantedList: ArrayList<Permissions> = new ArrayList()
      let deniedList: ArrayList<Permissions> = new ArrayList()
      //遍历开发者添加的权限是否已经授权，如果已经授权则移出列表
      this.mPermissions.forEach((permission) => {
        let result = this.checkPermission(permission)
        if (result) {
          //从临时列表里面移出
          temp.remove(permission)
          //添加到已授权权限列表
          this.push(permission, grantedList)
        }
      })
      //如果列表长度为 0 则表示权限已经全部授权，直接返回.否则对未授权的权限进行权限申请
      if (temp.length === 0) {
        resolve({ allGranted: true, grantedList, deniedList })
      } else {
        this.mAtManager.requestPermissionsFromUser(this.mContext, temp.convertToArray(), (error, requestResult) => {
          if (error) {
            //申请权限出错，抛出异常
            reject(error)
          } else {
            //对授权结果进行分类
            requestResult.authResults.forEach((authResult, index) => {
              if (authResult === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
                this.push(requestResult.permissions[index] as Permissions, grantedList)
              } else {
                this.push(requestResult.permissions[index] as Permissions, deniedList)
              }
              resolve({ allGranted: deniedList.length === 0, grantedList, deniedList })
            })
          }
        })
      }
    })
  }

  /**
   * add 数据前查重
   * @param element
   * @param arrayList
   */
  private push<T>(element: T, arrayList: ArrayList<T>) {
    if (!arrayList.has(element)) {
      arrayList.add(element)
    }
  }

  private checkPermission(permission: Permissions): boolean {
    let result = this.mAtManager.checkAccessTokenSync(this.mTokenId, permission)
    return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
  }
}

interface RequestResult {
  allGranted: boolean
  grantedList: ArrayList<Permissions>
  deniedList: ArrayList<Permissions>
}