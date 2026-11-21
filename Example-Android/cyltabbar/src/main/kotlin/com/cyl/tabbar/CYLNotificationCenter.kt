package com.cyl.tabbar

/**
 * [EN] A notification, as `NSNotification` on iOS: its name (`CYLConstants.…Notification`), the object it is about (for the
 *      tab change notifications: the tab's page) and its `userInfo` (keys `CYLConstants.…Key`).
 * [CN] 一条通知，与 iOS 的 `NSNotification` 相同：名称（`CYLConstants.…Notification`）、相关对象（Tab 变化通知中为该 Tab 的页面）
 *      以及 `userInfo`（key 为 `CYLConstants.…Key`）。
 */
class CYLNotification(val name: String, val `object`: Any?, val userInfo: Map<String, Any?>)

/**
 * [EN] `CYLNotificationCenter`: the Android counterpart of iOS's `NSNotificationCenter.defaultCenter` for this library's
 *      notifications. Observers run synchronously, on the thread that posts (the library posts on the main thread).
 *      ```kotlin
 *      val token = CYLNotificationCenter.addObserver(CYLConstants.CYLTabBarItemTitleDidChangeNotification, page) { note ->
 *          toolbar.title = note.userInfo[CYLConstants.CYLTabBarItemTitle] as? String
 *      }
 *      CYLNotificationCenter.removeObserver(token)   // e.g. in onDestroyView
 *      ```
 * [CN] `CYLNotificationCenter`：本库通知在 Android 上对应 iOS 的 `NSNotificationCenter.defaultCenter`。观察者在发送通知的线程上同步执行
 *      （本库在主线程发送）。
 */
object CYLNotificationCenter {

    /**
     * [EN] What `addObserver` returns; pass it to `removeObserver`. [CN] `addObserver` 的返回值，传给 `removeObserver`。
     */
    class Token internal constructor(internal val name: String?, internal val sender: Any?, internal val block: (CYLNotification) -> Unit)

    private val tokens = ArrayList<Token>()

    /**
     * [EN] Calls `block` for each notification named `name` (any name when null) about `sender` (any object when null).
     * [CN] 对每条名为 `name`（为 null 时不限名称）、关于 `sender`（为 null 时不限对象）的通知调用 `block`。
     */
    @JvmStatic
    @JvmOverloads
    fun addObserver(name: String?, sender: Any? = null, block: (CYLNotification) -> Unit): Token =
        Token(name, sender, block).also { synchronized(tokens) { tokens += it } }

    @JvmStatic
    fun removeObserver(token: Token) {
        synchronized(tokens) { tokens.remove(token) }
    }

    @JvmStatic
    @JvmOverloads
    fun post(name: String, sender: Any? = null, userInfo: Map<String, Any?> = emptyMap()) {
        val notification = CYLNotification(name, sender, userInfo)
        // [EN] A copy, so an observer may remove itself or add another one. [CN] 使用副本，观察者可以移除自己或添加其他观察者。
        val matching = synchronized(tokens) { tokens.filter { (it.name == null || it.name == name) && (it.sender == null || it.sender === sender) } }
        for (token in matching) token.block(notification)
    }
}
