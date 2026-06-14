1: lets build an amazing menubar for macos! initial idea is: i want a menubar on macos, in which i can see match schedules (main focus is is there any match today, if yes then show team name and time (latest game first)), while game is on i want to see real time scores, when any team makes goal, a simple animation that its a goal, maybe a footbool sprints through left to right in small space in the menubar area. so the inspiration is from this app: https://github.com/tareq1988/prayer-times-macos. see the image also. this is still my initial idea. this needs more ideas with it, please question and discuss with me, lets do a research first, then lets finalize the plan then build in one go.
- i will clone the inspiration repo for you so that you can take reference. i already did. check here the prayer-times-macos directory.
- whatever we build, it has to consume a tiny ram. DO NOT EVEN MAKE THE SYSMEM BUSY.
- we will never autostart with system (no login items), if anyone wants they will click to open the app > then i will stay in menubar.
- lets not require any window or anything, we will do everything in the menubar only. so thats why i am saying we need more discussions. so lets discuss. what to keep, what can be shown, what are the optimizations, colors schemes, animations.
- we will try to use very less amount of third party packages (if possible).

2: answer to 1: The one closest to a goal.
answer to 2: previous, today, tomorrow, whole month.
answer to 3: lets build the Tiny ⚨ emoji/text slides across the menu bar text area (subtle, lightweight) first. lets not complicate first.
answer to 4: your decisions are okay. but when no matches today: auto check at midnight. not every 1 hour. and on the panel, show a button named: sync. if anyone clicks sync. the app will sync then. and yes, polling live matches is acceptable but make it check 1 min. also give option to user if they want to change the polling interval. minimum is 1 min.
answer to 5: dynamic is so cool.
answer to 6: all okay.
answer to 7: keep it aside. lets build the main thing for now.

initiate required md files for this whole app. so that you dont forget any goal, my raw idea, my decisions, also inspiration ideas. so create md files first. then lets start building.

3: start building please. but before,
- please know that i initiated git in this repo. while building, keep commiting.
- those documentation files are so so good. thanks to you. shift them to docs/ folder maybe? that will be great. repo will look more clean.
- also maintain a md file where you will be writing internal notes, i am also maintaining a prompt.md file where i am writing all the propmts. so in later how many agents or llm is used in this project, they should know - in which stage is this project is.
- start the phase 1.

4: 