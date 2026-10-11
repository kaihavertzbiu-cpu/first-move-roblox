# Studio 检查入口

2026-10-10：新增 `localization-tests.lua`，覆盖离线词库、可逆切换、姓名保护和服务器语言设置兼容；`audio-feedback-tests.lua` 覆盖暗黑按钮音效池、尾音、静音及切页取消。语言扩展后的检查结果见 `../../generated/DARK_AUDIO_LOCALIZATION_ACCEPTANCE_2026-10-10.json`，数量表示重复布局 / 不变量断言，不能当作独立功能数量。英文几何检查使用相同 fixture 的 English 变体，中文与英文分别记录。临时双客户端 QA 不进入构建文件。

在已打开的主工程 **Edit 数据模型** 中，通过拥有脚本执行能力的 Studio 开发工具运行对应 Lua 文件内容。不要把检查代码放入正式运行脚本，不需要更改云端 API 或账号权限。

- session-recovery-tests.lua：服务器契约；正式服务源码与真实规则，替换传输、玩家、存档和调度器；含重复排队、原子转 AI、无残留队列和先配对后切换的竞争顺序。
- onboarding-tests.lua：隔离三步训练、真实恢复/冷却与存档兼容保护。
- field-guide-tests.lua：真实规则公开投影的双方选人指导与剩余次数；不等于双客户端 UI 操作。
- presentation-order-tests.lua：正式表现队列、特殊声音、HUD 同序与终局音乐；确定性调度器。
- client-recovery-tests.lua：控制器回调、恢复与局内设置；替换 GUI、传输、时钟和调度器；含等待计时、重复回执、连接/等待焦点、切换重试与失效回调。
- responsive-geometry-tests.lua：正式主菜单渲染器和局内设置，五个固定窗口尺寸；含局内大字号、转向、持久选项对象、文字/按钮边界、菜单覆盖及返回焦点。
- battle-geometry-tests.lua：正式战斗、战报与三步训练渲染器，五个窗口尺寸及大字号；包含等待界面长文案与转向、主按钮释放、攻击技能开关可见性、同局再战状态更新时战报阅读位置、窗口变化与不同对局重置；替换传输、时钟、镜头、音频和存档。
- targeting-flow-tests.lua：正式回调和真实 GUI 引擎，提交意图由真实规则接受；目标①②编辑、不同/同一目标限制、HUD 标记、不抢先提交、残影自毁交接。包含显式低 HP 与单存活敌方边界，不是自然实机完整局。
- resolution-effects-qa.lua：临时桌面副本与真实 Part/Tween；公开事件样本、阵亡顺序、减少运动、48 个 Part 上限和销毁检查。
- cinematic-feedback-tests.lua：临时 HUD/镜头，五种尺寸、提示可读性、输入透传、取消与减少运动；不代表真人观感或硬件签收。
- report-story-tests.lua：正式规则与终局公开视角的因果复盘，含双方全灭、镜像阵营与缺档边界；不是完整实机对局。
- live-tactical-acceptance.lua：Studio Client 中通过公共状态和正式 Intent 进行 AI 对局，等待 FirstMoveChainQA 的实际演出结束；不是真人游玩证据。
- live-chain-monitor.client.lua：临时 FirstMoveChainQA Folder 中的 LocalScript，需要 Result StringValue；记录正式运行表现，不嵌入工程。

GUI 检查会临时在 CoreGui 创建 FirstMoveGeometryQA / FirstMoveBattleGeometryQA，结束或断言失败后销毁。桌面检查也清理临时副本。返回值报告实际范围与断言数量，数量随样本和尺寸变化，以生成验收 JSON 为准。几何断言包含重复尺寸和不变量，不能当作同数量的独立用户功能。

live-ai-acceptance.lua 在 **Client Play** 中运行：先给 shared.FirstMoveAcceptance 附上公共 State 数据包观察器，实际通过菜单进入 AI 对局，再执行脚本。它仅根据公开状态发送正常 Intent，但不是真人理解度证据。音乐运行测试需在真实游戏 LocalScript 环境使用正式控制器，以免开发工具自身 ModuleScript 缓存制造重复播放实例。

真实鼠标、触摸、手柄、真人听感、发布云存档和延迟测试必须另外完成。最新战报检查见 ../../generated/REPORT_CONTINUITY_QA_2026-10-04.md，目标检查见 ../../generated/TARGETING_QA_2026-10-04.md，既有原生操作见 ../../generated/FORMAL_GUIDANCE_QA_2026-10-04.md；既有网络流程见 SESSION_AND_RESPONSIVE_QA.md、ONBOARDING_AND_REMATCH_QA.md 和 PVP_QA.md。本目录不参与 build.cjs 的脚本嵌入。
