import common from '@ohos.app.ability.common';
import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '../utils/Logger';
import json from '@ohos.util.json';
import { JSON } from '@kit.ArkTS';

/**
 * WebSocket连接状态枚举
 */
export enum WebSocketState {
  CONNECTING,
  OPEN,
  CLOSING,
  CLOSED
}

/**
 * WebSocket消息类型枚举
 */
export enum WebSocketMessageType {
  TEXT,
  BINARY
}

const TAG = '[WebSocket]';

export class WebsocketManager {
  private wsClient: webSocket.WebSocket | null = null;
  private state: WebSocketState = WebSocketState.CLOSED;
  private url: string = ''
  private heartbeatTimer: number = -1;
  private heartbeatInterval: number = 30000; // 默认30秒心跳间隔
  private reconnectTimer: number = -1;
  private reconnectInterval: number = 5000; // 重连间隔
  private maxReconnectTimes: number = 5;
  private currentReconnectTimes: number = 0;
  // 回调函数
  private onOpenCallback: (() => void) | null = null;
  private onMessageCallback: ((data: string | ArrayBuffer, type: WebSocketMessageType) => void) | null = null;
  private onErrorCallback: ((error: Error) => void) | null = null;
  private onCloseCallback: ((code: number, reason: string) => void) | null = null;

  /**
   * 连接WebSocket服务器
   */
  public connect(url: string): void {
    if (this.state === WebSocketState.CONNECTING || this.state === WebSocketState.OPEN) {
      return;
    }

    this.url = url;
    this.state = WebSocketState.CONNECTING;

    try {
      if (!this.wsClient) {
        this.wsClient = webSocket.createWebSocket();
      }

      this.wsClient.on('open', () => {
        Logger.info(TAG, 'WebSocket连接 open');
        this.state = WebSocketState.OPEN;
        this.resetReconnect();
        this.startHeartbeat();
        this.onOpenCallback?.();
      });

      this.wsClient.on('message', (err, data: string | ArrayBuffer) => {
        if (data instanceof ArrayBuffer) {
          this.onMessageCallback?.(data, WebSocketMessageType.BINARY);
        } else if (typeof data === 'string') {
          this.onMessageCallback?.(data, WebSocketMessageType.TEXT);
        }
      });

      this.wsClient.on('error', (error) => {
        Logger.info(TAG, 'WebSocket连接 error');
        this.state = WebSocketState.CLOSED;
        this.onErrorCallback?.(error);
        this.reconnect();
      });

      this.wsClient.on('close', (event) => {
        Logger.info(TAG, 'WebSocket连接 close');
        this.state = WebSocketState.CLOSED;
        // 非主动关闭时尝试重连
        if (event && event.code !== 1000) {
          this.reconnect();
        } else {
          this.onCloseCallback?.(event.code, event.message);
        }
      });

      let key = 'sk-c6d7f09f5b634ee6ab9d860643750004gwvpvqt2jeeb5p5z';
      let option: webSocket.WebSocketRequestOptions = {
        header: { 'Authorization': `Bearer ${key}` }
      };
      this.wsClient.connect(url, option, () => {
        Logger.debug(TAG, '连接成功');
      });
    } catch (error) {
      this.state = WebSocketState.CLOSED;
      this.onErrorCallback?.(error as Error);
      Logger.error(TAG, '连接失败:' + error);
    }
  }

  /**
   * 发送语音字节流
   * @param audioData 语音数据
   */
  public sendAudioData(audioData: ArrayBuffer): void {
    if (this.state !== WebSocketState.OPEN) {
      Logger.error(TAG, 'WebSocket未连接，无法发送语音数据');
      return;
    }

    try {
      this.wsClient?.send(audioData).then(() => {
        Logger.info(TAG, '语音数据发送成功');
      }).catch((error: BusinessError) => {
        Logger.error(TAG, '语音数据发送失败:' + error.message);
        this.onErrorCallback?.(error);
      });
    } catch (error) {
      Logger.error(TAG, '发送语音数据时出错:' + error);
      this.onErrorCallback?.(error as Error);
    }
  }

  /**
   * 发送文本消息
   * @param message 文本消息
   */
  public sendTextMessage(message: string): void {
    if (this.state !== WebSocketState.OPEN) {
      Logger.error(TAG, 'WebSocket未连接，无法发送文本消息');
      return;
    }

    // Logger.debug(TAG, `发送文本消息: ${message}`);
    try {
      this.wsClient?.send(message).then(() => {
        // Logger.info(TAG, '文本消息发送成功:'+message.length);
      }).catch((error: BusinessError) => {
        Logger.error(TAG, '文本消息发送失败:' + error.message);
        this.onErrorCallback?.(error);
      });
    } catch (error) {
      Logger.error(TAG, '发送文本消息时出错:' + error);
      this.onErrorCallback?.(error as Error);
    }
  }

  /**
   * 关闭WebSocket连接
   * @param code 关闭码
   * @param reason 关闭原因
   */
  public close(code: number = 1000, reason: string = 'Normal closure'): void {
    if (this.state === WebSocketState.CLOSED || this.state === WebSocketState.CLOSING) {
      return;
    }

    this.state = WebSocketState.CLOSING;
    this.stopHeartbeat();
    this.resetReconnect();
    try {
      this.wsClient?.close({
        code: code,
        reason: reason
      }).then(() => {
        Logger.info(TAG, 'WebSocket关闭成功');
      }).catch((error: BusinessError) => {
        Logger.error(TAG, 'WebSocket关闭失败:' + error.message);
        this.onErrorCallback?.(error);
      });
    } catch (error) {
      Logger.error(TAG, '关闭WebSocket时出错:' + error);
      this.onErrorCallback?.(error as Error);
    }
  }

  /**
   * 设置连接成功回调
   * @param callback 回调函数
   */
  public setOnOpenCallback(callback: () => void): void {
    this.onOpenCallback = callback;
  }

  /**
   * 设置消息接收回调
   * @param callback 回调函数
   */
  public setOnMessageCallback(callback: (data: string | ArrayBuffer, type: WebSocketMessageType) => void): void {
    this.onMessageCallback = callback;
  }

  /**
   * 设置错误回调
   * @param callback 回调函数
   */
  public setOnErrorCallback(callback: (error: Error) => void): void {
    this.onErrorCallback = callback;
  }

  /**
   * 设置关闭回调
   * @param callback 回调函数
   */
  public setOnCloseCallback(callback: (code: number, reason: string) => void): void {
    this.onCloseCallback = callback;
  }

  /**
   * 获取当前连接状态
   */
  public getState(): WebSocketState {
    return this.state;
  }

  // 发送心跳
  private sendHeartbeat(): void {
    if (this.state != WebSocketState.OPEN || !this.wsClient) {
      return;
    }

    try {
      this.sendTextMessage('ping');
      console.info('发送心跳包');
    } catch (error) {
      console.error(`心跳发送失败: ${JSON.stringify(error)}`);
    }
  }

  // 开始心跳
  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setTimeout(() => {
      this.sendHeartbeat();
      this.startHeartbeat();
    }, this.heartbeatInterval) as number;
  }

  // 停止心跳
  private stopHeartbeat(): void {
    if (this.heartbeatTimer !== -1) {
      clearTimeout(this.heartbeatTimer);
      this.heartbeatTimer = -1;
    }
  }

  // 重连机制
  private reconnect(): void {
    if (this.currentReconnectTimes >= this.maxReconnectTimes) {
      console.error('达到最大重连次数，停止重连');
      return;
    }

    this.stopHeartbeat();
    this.reconnectTimer = setTimeout(() => {
      console.info(`尝试重连 (${this.currentReconnectTimes + 1}/${this.maxReconnectTimes})`);
      this.currentReconnectTimes++;
      this.connect(this.url);
    }, this.reconnectInterval) as number;
  }

  // 重置重连计数
  private resetReconnect(): void {
    this.currentReconnectTimes = 0;
    if (this.reconnectTimer !== -1) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }
  }
}