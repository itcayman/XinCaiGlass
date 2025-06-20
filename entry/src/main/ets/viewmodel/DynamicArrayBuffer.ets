export class DynamicArrayBuffer {
  capacity: number;
  buffer: ArrayBuffer;
  view: Uint8Array;
  length: number;

  constructor(initialCapacity = 1024) {
    this.capacity = initialCapacity;
    this.buffer = new ArrayBuffer(this.capacity);
    this.view = new Uint8Array(this.buffer);
    this.length = 0;
  }

  // 添加新的ArrayBuffer
  append(buffer: ArrayBuffer) {
    const bufferLength = buffer.byteLength;
    // 检查是否需要扩容
    if (this.length + bufferLength > this.capacity) {
      this._resize(this.length + bufferLength);
    }
    // 复制数据
    this.view.set(new Uint8Array(buffer), this.length);
    this.length += bufferLength;
  }

  // 获取当前数据的视图
  getBuffer() {
    return this.buffer.slice(0, this.length);
  }

  // 扩容
  _resize(minCapacity: number) {
    let newCapacity = this.capacity;
    while (newCapacity < minCapacity) {
      newCapacity *= 2;
    }

    const newBuffer = new ArrayBuffer(newCapacity);
    const newView = new Uint8Array(newBuffer);
    newView.set(this.view.subarray(0, this.length));

    this.buffer = newBuffer;
    this.view = newView;
    this.capacity = newCapacity;
  }
}
