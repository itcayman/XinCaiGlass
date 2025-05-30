
export class GlassManager {
  private static instance: GlassManager

  public static getInstance(): GlassManager {
    if (!GlassManager.instance) {
      GlassManager.instance = new GlassManager()
    }
    return GlassManager.instance
  }

}