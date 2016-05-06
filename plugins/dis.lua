do function run(msg, matches)if string.len(matches[1]) > 15 then return "  فقط بیست حرف" end
return "کلمه شما با اشکال زیر زیبا شد\n------------------------------- ▌│█║▌║▌║"..matches[1].."║▌║▌║█│\n\n¸,ø¤º°`°๑۩"..matches[1].."۩ ๑,¸¸,ø¤º°`\n\n┏┛┗┓┏┛┗┓"..matches[1].."┗┓┏┛┗┓┏┛\n\n（￣～￣）八"..matches[1].."八（￣～￣）\n\n ¯`·.¸¸.-> °º "..matches[1].." º° <-.¸¸.·´¯)\n\n¯``•.¸¸.•`"..matches[1].." `•.¸¸.•´´¯ \n\n°º¤ø,¸¸,ø¤º°"..matches[1].."°º¤ø,¸¸,ø¤º\n\nıllıllı"..matches[1].."ıllıllı\n\n▁ ▂ ▄ ▅ ▆ ▇ █"..matches[1].."█ ▇ ▆ ▅ ▄ ▂ ▁ \n\n©º°¨¨°º©"..matches[1].."©º°¨¨°º©\n\n ★·.·´¯`·.·★"..matches[1].."★·.·´¯`·.·★\n\n »-(¯`v´¯)-»"..matches[1].."»-(¯`v´¯)-»\n\n*´`*.¸.*´`*"..matches[1].."*´`*.¸.*´`*\n\n•°¯`••"..matches[1].."•°¯`••\n\n.o0×X×0o."..matches[1]..".o0×X×0o.\n\n๑۞๑°>>"..matches[1].."<<°๑۞๑\n\n*(¯`★´¯)*"..matches[1].."*(¯`★´¯)* \n\n°l||l°"..matches[1].."°l||l°\n\n···^v´¯`×"..matches[1].."×´¯`v^···\n by behrad"
  end return {
  description = "زیبا سازی متن", 
  usage = "dis msg",
  patterns = { "^[Dd]is (.*)",  },  run = run }end
--by behrad--

