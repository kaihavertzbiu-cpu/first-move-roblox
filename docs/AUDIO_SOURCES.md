# 先攻 / FIRST MOVE — 音源登记

## 暗黑界面按钮（2026-10-10）

新增 ProSoundEffects 的 **Toggle Switch Metal Industrial Equipment 34 (SFX)**，SoundId 9120103996，来源 https://create.roblox.com/store/asset/9120103996 。按 Roblox Creator Store 平台音频登记，不标注 CC BY，也没有复制英雄联盟音效或下载原音频。通过低速金属卡扣、既有冲击 / 气流层、EQ 与短混响区别选择、确认、提交和返回。实际客户端新音源及七个生产音效预加载均成功；真人听感和发布后的权限仍待验收。详细混音与语言收尾见 docs/19_DARK_UI_AUDIO_AND_LOCALIZATION.md。

## 自适应音乐（2026-10-02）

以下三段来自 APMOfficial，通过 Roblox SoundId 在平台内播放；没有下载、再分发或嵌入原始音频文件。它们属于 Roblox Licensed Music，**不沿用界面音源的 CC BY 许可**。平台使用说明：[Using Licensed Music on Roblox](https://en.help.roblox.com/hc/en-us/articles/360000927163-Using-Licensed-Music-on-Roblox)；条款：[Roblox Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use)。这些来源页面已核查，实际客户端预加载成功。

| 状态 | 音源 | 作者 | Creator Store 来源 | 客户端长度 |
| --- | --- | --- | --- | --- |
| 部署/菜单 | Low Drone 2 | APMOfficial | https://create.roblox.com/store/asset/1843828305 | 124.040 秒 |
| 交战 | Grey Shores main | APMOfficial | https://create.roblox.com/store/asset/9040092810/Grey-Shores-main | 129.489 秒 |
| 残局 | Tension Bed for One | APMOfficial | https://create.roblox.com/store/asset/1837463124/Tension-Bed-for-One | 133.443 秒 |

游戏片尾单独显示音轨、链接、平台许可说明与“Courtesy of APM Music”。三个 ID 同时写入 BUILD_MANIFEST.json。混音使用低增益、EQ、交叉淡出与关键音效压低；这是三段音乐切换。实际播放、压低/恢复、独立静音、完整对局切换通过，详见 RESOLUTION_AND_MUSIC_QA_2026-10-02.md；真人听感与生产环境资产可用性仍待验收。

## 战斗冲击与技能音源（2026-10-02）

在 Creator Store Audio 中筛选免费短音源，选用 ProSoundEffects 发布记录；只引用 SoundId，没有下载原文件或插入模型/脚本。Roblox 官方说明该库包含可用于游戏的专业音效：[Audio assets](https://create.roblox.com/docs/audio/assets)。这里按平台音频使用来源登记，不标注为 CC BY。

| 用途 | 音源 | 发布者 | 来源 |
| --- | --- | --- | --- |
| 技能起手 | Magic Zoom Up Sharp Tubular Whoosh Fast Hiss 8 | ProSoundEffects | https://create.roblox.com/store/asset/9125648149 |
| 击杀/处决/终局 | Metal Impact Sledge Hammer Hits On 5 Ft I-Beam 13 | ProSoundEffects | https://create.roblox.com/store/asset/9125672726 |
| 普通冲击 | Robot Impact Miscellaneous Metal Clangs Clunks 4 | ProSoundEffects | https://create.roblox.com/store/asset/9125819216 |

实际客户端三者 Loaded=true。游戏片尾有独立“Courtesy of Pro Sound Effects”与资产来源说明，BUILD_MANIFEST.json 已登记；通过调速、短包络、EQ 与低增益混音区分反馈。音频加载与触发已经验证，真人听感、是否适合长期连局与发布环境可用性仍待验收。见 CINEMATIC_FEEDBACK_QA_2026-10-02.md。

## 原界面音源记录

2026-10-02 补充：七种技能分别配置起手 cue，修复/封锁复用 AgentAST 音源，处决/穿射/弹幕复用 whoosh，怒压/终响复用 metal；连续击破也复用 metal 并递进调速。没有新增外部资产，现有来源与署名保持。七技能实际播放、回退、静音和 Reset 运行证据见 CHAIN_AND_OUTCOME_ACCEPTANCE_2026-10-02.json；七种配置不等于七段独立录音，真人听感仍待签收。

2026-10-01。通过 Roblox Studio 的 Creator Store 搜索接口筛选免费 Audio；仅引用音频资产，不导入模型、脚本或执行依赖。

| 音源 | 作者 | Creator Store 来源 | 作者标注许可 | 首次候选预载 |
| --- | --- | --- | --- | --- |
| Button 8 / Sci-fi Interface GUI | AgentAST | https://create.roblox.com/store/asset/2789465276 | CC BY Attribution 3.0 | 成功，0.653 秒 |
| Button 4 / Sci-fi Interface GUI | AgentAST | https://create.roblox.com/store/asset/2789458365 | CC BY Attribution 3.0 | 成功，1.202 秒 |
| Acknowledgment 2 / Sci-fi Interface GUI | AgentAST | https://create.roblox.com/store/asset/2789469408 | CC BY Attribution 3.0 | 成功，0.784 秒 |

许可链接：https://creativecommons.org/licenses/by/3.0/ 。资产搜索返回的原描述均标注该许可。改编包含剪辑、调速、淡出、EQ 和混音；作者、原音源名称、来源与许可已加入游戏片尾的可滚动资料页。所引资产全部为 Audio，无外部代码可执行。主工程 Build Manifest 登记这三个 ID。

分别用于选择、承诺/确认与能核揭示、胜负提示，并通过调速与包络区分处决、命线等事件。新界面音源未加载时，使用内置采样作为回退；悬停与战斗撞击仍用低增益内置采样。音乐另见以下登记。

重新启动后，三个自定义音源与两个内置回退均在实际客户端加载成功。生产 LocalScript 已验证静音、强制自定义音源不可用时回退、返回菜单取消胜利尾音；正常镜头终局 FOV 45，减少运动约 46。正式 AI 对局与双客户端 PvP 均完成终局演出。截图及记录见 OUTCOME_ACCEPTANCE.json、PVP_ACCEPTANCE.json 和 evidence/。真人听感仍需验收。来源页面的通用网页抓取未成功，资产信息以 Creator Store 搜索接口返回为依据。
