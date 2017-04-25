// LSLScripts.nPose LMLG chains plugin.lslp 
// 2017-04-25 20:39:16 - LSLForge (0.1.9.3) generated
// Started at: 04.05.2013 17:04:00
// Authors: XandrineX and Perl Nakajima
// Modified by Pfil Payne: 
// - make the Plugin usable for more than on victim
// - add LMv2 compatibility
// - scan for leashpoints, if the cuffs add later
// - Particel config
// texture = particle texture as uuid
// xsize   = particle X size as float (0.03125 to 4.0)
// ysize   = particle Y size as float (0.03125 to 4.0)
// gravity = particle gravity as float
// life    = particle life time as float in seconds
// red     = red part of the particle color as float (0 to 1)
// green   = green part of the particle color as float (0 to 1)
// blue    = blue part of the particle color as float (0 to 1)



// particel
string gTexture = "245ea72d-bc79-fee3-a802-8e73c0f09473";
float gXsize = 6.999999999999999e-2;
float gYsize = 6.999999999999999e-2;
float gGravity = 3.0e-2;
float gLife = 1;
float gRed = 1;
float gGreen = 1;
float gBlue = 1;
string gSET_SEPARATOR = "~";

// For trying to use lockguard as a fallback, you need to specify mappings here
// from the lockmeister to lockguard attachment IDs. I know that this is not
// perfect, since lockmeister and lockguard offer different cuff points and
// additionally work just the other way round. So I tried to do my best and
// give the best mapping I could think of. But you might need to change it,
// depending on your needs and piece of furniture.
// For reference and available points, see:
// http://wiki.secondlife.com/wiki/LSL_Protocol/LockMeister_System
// http://lslwiki.net/lslwiki/wakka.php?wakka=exchangeLockGuardItem
list gLM_TO_LG_MAPPINGS = ["rcuff","rightwrist","rbiceps","rightupperarm","lbiceps","leftupperarm","lcuff","leftwrist","lblade","harnessleftloopback","rblade","harnessrightloopback","rnipple","rightnipplering","lnipple","leftnipplering","rfbelt","rightbeltloop","lfbelt","leftbeltloop","rtigh","rightupperthigh","ltigh","leftupperthigh","rlcuff","rightankle","llcuff","leftankle","lbbelt","harnessleftloopback","rbbelt","harnessrightloopback","pelvis","clitring","fbelt","frontbeltloop","bbelt","backbeltloop","rcollar","collarrightloop","lcollar","collarleftloop","thead","topheadharness","collar","collarfrontloop","lbit","leftgag","rbit","rightgag","nose","nosering","bcollar","collarbackloop","back","harnessbackloop","lhand","leftwrist","rhand","rightwrist"];

// --- global variables ---
list gPrimIDs;
list gLmCalls;
integer gLmCallsLength;
integer gListenLMHandle;
integer gListenLGHandle;
list gSetChains;
list gMissingChainPoints;
list gParticles;
integer gTimerMode;

// ============================================================
list ListItemDelete(list mylist,string element_old){
  integer placeinlist = llListFindList(mylist,[element_old]);
  if ((placeinlist != -1)) return llDeleteSubList(mylist,placeinlist,placeinlist);
  return mylist;
}

query_set_chains(key avatarKey,list items){
  integer itemLength = llGetListLength(items);
  if ((gListenLMHandle == -1)) (gListenLMHandle = llListen(-8888,"",NULL_KEY,""));
  if ((gListenLGHandle == -1)) (gListenLGHandle = llListen(-9119,"",NULL_KEY,""));
  integer i;
  for ((i = 0); (i < itemLength); (i += 2)) {
    string desc = llList2String(items,i);
    integer index = llListFindList(gPrimIDs,[desc]);
    if ((index == -1)) {
    }
    else  {
      integer primId = llList2Integer(gPrimIDs,(index + 1));
      llLinkParticleSystem(primId,[]);
      string mooring = llList2String(items,(i + 1));
      if ((mooring != "")) {
        string lm_call = (((string)avatarKey) + mooring);
        if ((-1 == llListFindList(gLmCalls,[(lm_call + " ok")]))) {
          llWhisper(-8888,lm_call);
          (index = llListFindList(gLM_TO_LG_MAPPINGS,[mooring]));
          if ((index != -1)) {
            string lgMooring = llList2String(gLM_TO_LG_MAPPINGS,(index + 1));
            key primKey = llGetLinkKey(primId);
            llWhisper(-9119,(((((((((((((((((((((("lockguard " + ((string)avatarKey)) + " ") + lgMooring) + " texture ") + gTexture) + " size ") + ((string)gXsize)) + " ") + ((string)gYsize)) + " gravity ") + ((string)gGravity)) + " color ") + ((string)gRed)) + " ") + ((string)gGreen)) + " ") + ((string)gBlue)) + " life ") + ((string)gLife)) + " link ") + ((string)primKey)) + " ping"));
            (gSetChains += [desc,avatarKey,mooring,lgMooring]);
          }
          else  {
            (gSetChains += [desc,avatarKey,mooring,"-"]);
          }
          (gLmCalls += [(lm_call + " ok"),primId]);
          (gMissingChainPoints += [desc]);
        }
      }
    }
  }
  (gLmCallsLength = llGetListLength(gLmCalls));
  (gTimerMode = 1);
  llSetTimerEvent(3);
}

query_rem_chains(key avatarKey,list descriptions){
  integer length = llGetListLength(descriptions);
  integer i;
  for ((i = 0); (i < length); (i += 1)) {
    string description = llList2String(descriptions,i);
    integer index = llListFindList(gPrimIDs,[description]);
    if ((index != -1)) {
      llLinkParticleSystem(llList2Integer(gPrimIDs,(index + 1)),[]);
    }
    else  {
    }
    (index = llListFindList(gSetChains,[description]));
    if ((~index)) {
      llWhisper(-9119,(((("lockguard " + ((string)llList2Key(gSetChains,(index + 1)))) + " ") + llList2String(gSetChains,(index + 3))) + " unlink"));
      (gSetChains = llDeleteSubList(gSetChains,index,(index + 3)));
    }
    (gMissingChainPoints = ListItemDelete(gMissingChainPoints,description));
  }
}

update_chains(){
  if ((gListenLMHandle == -1)) (gListenLMHandle = llListen(-8888,"",NULL_KEY,""));
  if ((gListenLGHandle == -1)) (gListenLGHandle = llListen(-9119,"",NULL_KEY,""));
  integer length = llGetListLength(gSetChains);
  integer i;
  for ((i = 0); (i < length); (i += 4)) {
    string desc = llList2String(gSetChains,i);
    integer index = llListFindList(gPrimIDs,[desc]);
    integer primId = llList2Integer(gPrimIDs,(index + 1));
    string mooring = llList2String(gSetChains,(i + 2));
    string lm_call = (((string)llList2Key(gSetChains,(i + 1))) + mooring);
    llWhisper(-8888,lm_call);
    string lgMooring = llList2String(gSetChains,(i + 3));
    if ((lgMooring != "-")) {
      key primKey = llGetLinkKey(primId);
      llWhisper(-9119,(((((((((((((((((((((("lockguard " + ((string)llList2Key(gSetChains,(i + 1)))) + " ") + lgMooring) + " texture ") + gTexture) + " size ") + ((string)gXsize)) + " ") + ((string)gYsize)) + " gravity ") + ((string)gGravity)) + " life ") + ((string)gLife)) + " color ") + ((string)gRed)) + " ") + ((string)gGreen)) + " ") + ((string)gBlue)) + " link ") + ((string)primKey)) + " ping"));
    }
    (gLmCalls += [(lm_call + " ok"),primId]);
  }
  (gLmCallsLength = llGetListLength(gLmCalls));
  (gTimerMode = 1);
  llSetTimerEvent(3);
}

control_chains(){
  if ((gListenLMHandle == -1)) (gListenLMHandle = llListen(-8888,"",NULL_KEY,""));
  if ((gListenLGHandle == -1)) (gListenLGHandle = llListen(-9119,"",NULL_KEY,""));
  integer length = llGetListLength(gMissingChainPoints);
  integer i2;
  for ((i2 = 0); (i2 < length); (i2 += 1)) {
    string desc = llList2String(gMissingChainPoints,i2);
    integer i = llListFindList(gSetChains,[desc]);
    integer index = llListFindList(gPrimIDs,[desc]);
    integer primId = llList2Integer(gPrimIDs,(index + 1));
    string mooring = llList2String(gSetChains,(i + 2));
    string lm_call = (((string)llList2Key(gSetChains,(i + 1))) + mooring);
    llWhisper(-8888,lm_call);
    string lgMooring = llList2String(gSetChains,(i + 3));
    if ((lgMooring != "-")) {
      key primKey = llGetLinkKey(primId);
      llWhisper(-9119,(((((((((((((((((((((("lockguard " + ((string)llList2Key(gSetChains,(i + 1)))) + " ") + lgMooring) + " texture ") + gTexture) + " size ") + ((string)gXsize)) + " ") + ((string)gYsize)) + " gravity ") + ((string)gGravity)) + " life ") + ((string)gLife)) + " color ") + ((string)gRed)) + " ") + ((string)gGreen)) + " ") + ((string)gBlue)) + " link ") + ((string)primKey)) + " ping"));
    }
    (gLmCalls += [(lm_call + " ok"),primId]);
  }
  (gLmCallsLength = llGetListLength(gLmCalls));
  (gTimerMode = 1);
  llSetTimerEvent(3);
}

query_config(key avatarKey,list items){
  integer length = llGetListLength(items);
  integer i;
  for ((i = 0); (i < length); (i += 1)) {
    list line = llParseString2List(llList2String(items,i),["="],[]);
    string item = llList2String(line,0);
    if ((item == "texture")) (gTexture = llList2String(line,1));
    else  if ((item == "xsize")) (gXsize = llList2Float(line,1));
    else  if ((item == "ysize")) (gYsize = llList2Float(line,1));
    else  if ((item == "gravity")) (gGravity = llList2Float(line,1));
    else  if ((item == "life")) (gLife = llList2Float(line,1));
    else  if ((item == "red")) (gRed = llList2Float(line,1));
    else  if ((item == "green")) (gGreen = llList2Float(line,1));
    else  if ((item == "blue")) (gBlue = llList2Float(line,1));
  }
  set_particle();
  update_chains();
}

set_particle(){
  (gParticles = [5,<gXsize,gYsize,0.0>,6,<gXsize,gYsize,0.0>,7,gLife,8,<0.0,0.0,(gGravity * -1)>,12,gTexture,9,1,15,2,13,0.1,1,<gRed,gGreen,gBlue>,3,<gRed,gGreen,gBlue>,0,114]);
}
// ============================================================
default {

    state_entry() {
    (gPrimIDs = []);
    (gSetChains = []);
    (gLmCalls = []);
    (gListenLMHandle = -1);
    (gListenLGHandle = -1);
    integer number_of_prims = llGetNumberOfPrims();
    integer i;
    for ((i = 1); (i < (number_of_prims + 1)); (++i)) {
      string desc = llList2String(llGetLinkPrimitiveParams(i,[28]),0);
      if (((desc != "") && (desc != "(No description)"))) {
        if ((-1 == llListFindList(gPrimIDs,[desc]))) {
          (gPrimIDs += [desc,i]);
        }
        else  {
          llOwnerSay((("/me Error: prim description " + desc) + " isn't unique, please make it unique... ignoring"));
        }
      }
    }
    set_particle();
  }


    link_message(integer primId,integer commandId,string message,key avatarKey) {
    if ((commandId == 2733)) {
      query_rem_chains(avatarKey,llParseStringKeepNulls(message,[gSET_SEPARATOR],[]));
    }
    else  if ((commandId == 2732)) {
      query_set_chains(avatarKey,llParseStringKeepNulls(message,[gSET_SEPARATOR],[]));
    }
    else  if ((commandId == 2734)) {
      query_config(avatarKey,llParseStringKeepNulls(message,[gSET_SEPARATOR],[]));
    }
  }

    
    listen(integer channel,string cuffName,key cuffKey,string message) {
    if ((channel == -9119)) {
      list s = llParseStringKeepNulls(message,[" "],[]);
      key avatar = llList2Key(s,1);
      string lgmooring = llList2String(s,2);
      integer index = llListFindList(gLM_TO_LG_MAPPINGS,[lgmooring]);
      if ((index != -1)) {
        string mooring = llList2String(gLM_TO_LG_MAPPINGS,(index - 1));
        string lm_call = ((((string)avatar) + mooring) + " ok");
        integer i = llListFindList(gLmCalls,((list)lm_call));
        if ((~i)) {
          integer i2 = llListFindList(gPrimIDs,[llList2Integer(gLmCalls,(i + 1))]);
          string desc = llList2String(gPrimIDs,(i2 - 1));
          (gMissingChainPoints = ListItemDelete(gMissingChainPoints,desc));
        }
      }
    }
    else  if ((channel == -8888)) {
      integer i;
      if ((llGetSubString(message,-2,-1) == "ok")) {
        (i = llListFindList(gLmCalls,((list)message)));
        if ((~i)) {
          integer index = llListFindList(gLM_TO_LG_MAPPINGS,[llGetSubString(message,36,-4)]);
          llWhisper(-9119,(((("lockguard " + llGetSubString(message,0,35)) + " ") + llList2String(gLM_TO_LG_MAPPINGS,(index + 1))) + " unlink "));
          llLinkParticleSystem(llList2Integer(gLmCalls,(i + 1)),(gParticles + [20,cuffKey]));
          llRegionSayTo(((key)llGetSubString(message,0,35)),-8888,((llGetSubString(message,0,35) + "|LMV2|RequestPoint|") + llGetSubString(message,36,-4)));
          (gTimerMode = 1);
          llSetTimerEvent(3);
          integer i2 = llListFindList(gPrimIDs,[llList2Integer(gLmCalls,(i + 1))]);
          string desc = llList2String(gPrimIDs,(i2 - 1));
          (gMissingChainPoints = ListItemDelete(gMissingChainPoints,desc));
        }
      }
      else  {
        list temp = llParseString2List(message,["|"],[""]);
        if (((llList2String(temp,1) == "LMV2") && (llList2String(temp,2) == "ReplyPoint"))) {
          (i = llListFindList(gLmCalls,((list)((llList2String(temp,0) + llList2String(temp,3)) + " ok"))));
          if ((~i)) {
            llLinkParticleSystem(llList2Integer(gLmCalls,(i + 1)),(gParticles + [20,((key)llList2String(temp,4))]));
          }
        }
      }
    }
  }


    timer() {
    if ((gTimerMode == 1)) {
      llSetTimerEvent(0.0);
      llListenRemove(gListenLMHandle);
      (gListenLMHandle = -1);
      llListenRemove(gListenLGHandle);
      (gListenLGHandle = -1);
      (gLmCalls = []);
      if (llGetListLength(gMissingChainPoints)) {
        (gTimerMode = 2);
        llSetTimerEvent(15);
      }
    }
    else  if ((gTimerMode == 2)) {
      if (llGetListLength(gMissingChainPoints)) {
        control_chains();
      }
      else  llSetTimerEvent(0.0);
    }
  }

    
    on_rez(integer param) {
    llResetScript();
  }
}
