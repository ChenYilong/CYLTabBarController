#!/bin/bash
# [EN] Drives the example in WeChat DevTools through `wechatide` (the DevTools CLI skill, client name Claude). Source it,
#      then call the functions; run it outside a sandbox (wechatide opens the IDE and talks to its local port).
#        source scripts/cyl_devtools.sh
#        cyl_refresh                       # recompile the simulator
#        cyl_state "{overrides:{cylDemoIcons:'rive'}}"   # change the example's tab bar state
#        cyl_tap discover                  # tap a tab through the component
#        cyl_shot 18-rive-dark             # screenshot to docs/assets/wechat-miniprogram-api-<name>.png
#        cyl_playback discover             # tap a tab, then print the selected icon's frames every 100 ms
#      Prerequisites: DevTools with "Settings > Security > Service port" on, `wechatide` authorized for client "Claude".
# [CN] 通过 `wechatide`（开发者工具 CLI skill，客户端名 Claude）在微信开发者工具中驱动示例。先 source，再调用函数；
#      需在沙箱外运行（wechatide 会打开 IDE 并连接其本地端口）。用法见上。前提：开发者工具已开启「设置 > 安全 >
#      服务端口」，并已为客户端 "Claude" 授权。
CYL_EXAMPLE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
CYL_ASSETS="$(cd "$CYL_EXAMPLE/../../../docs/assets" && pwd)"

cyl_wechatide() { timeout 200 wechatide -c Claude "$@" 2>&1 | grep -v -E "codesign_util|skill-call"; }
cyl_eval() { cyl_wechatide automation_evaluate --project "$CYL_EXAMPLE" --fn-source "$1" | grep '"result": "' | tail -1; }
cyl_refresh() { cyl_wechatide simulator_refresh --project "$CYL_EXAMPLE" | grep -c '"success": true'; }
cyl_shot() { sleep "${2:-1}"; cyl_wechatide simulator_screenshot --project "$CYL_EXAMPLE" --optimize false --path "$CYL_ASSETS/wechat-miniprogram-api-$1.png" | grep -c '"success": true'; }
cyl_console() { cyl_wechatide get_simulator_console --project "$CYL_EXAMPLE" --command "${1:-grep -n -i error}"; }
cyl_state() { cyl_eval "function(){ getApp().cyl_updateTabBarState($1); return 'state'; }"; }
cyl_tap() { cyl_eval "function(){ const p=getCurrentPages(); p[p.length-1].getTabBar().selectComponent('#cyl-tab-bar').cyl_onTap({currentTarget:{dataset:{key:'$1'}}}); return 'tap $1'; }"; }

# [EN] A probe that spans a page switch cannot wait inside one evaluation (the automator times out), so it stores its
#      samples on getApp() and a second evaluation reads them.
# [CN] 跨越页面切换的探测不能在一次执行中等待（automator 会超时），因此把采样存在 getApp() 上，再用第二次执行读取。
cyl_playback() {
  cyl_eval "function(){ const app=getApp(); app.cylProbe=[]; const p0=getCurrentPages(); const key='$1';
    p0[p0.length-1].getTabBar().selectComponent('#cyl-tab-bar').cyl_onTap({currentTarget:{dataset:{key}}});
    const t=Date.now(); const tick=()=>{ const p=getCurrentPages(); const page=p[p.length-1]; let info='-';
      try { const it=page.getTabBar().selectComponent('#cyl-tab-bar').selectComponent('#cyl-item-'+key);
        const v=it && it.selectComponent('#cyl-item-animation'); const a=v && v.cylAnimation;
        const s=v && v.cylState; const input=s && v.cyl_input && v.cyl_input('active');
        info=page.route.split('/')[1]+(a ? ' frame='+Math.round(a.currentFrame)+(a.isPaused?' paused':'') : '')
          +(input ? ' active='+input.asBool().value : ''); } catch(e){ info='error '+e.message }
      app.cylProbe.push((Date.now()-t)+'ms '+info); if (Date.now()-t<2000) setTimeout(tick,100); };
    tick(); return 'probing $1'; }" >/dev/null
  sleep 5
  cyl_eval "function(){ return getApp().cylProbe.join(' | '); }"
}
