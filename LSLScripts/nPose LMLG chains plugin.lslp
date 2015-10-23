// Started at: 04.05.2013 17:04:00
// Authors: XandrineX and Perl Nakajima
// Modified from Pfil Payne: 
// - make the Plugin usable for more then on victim
// - add LMv2 compatibility
// - scan for leashpoints, if the cuffs add later
// - Particel config
// texture = particle texture as uuid
// xsize   = particle X size as float (0.03125 to 4.0)
// ysize   = particle Y size as float (0.03125 to 4.0)
// gravity = particle gravity as float
// life	= particle life time as float in seconds

// --- configuration ---
float   gLOCKMEISTER_RESPONSE_TIMEOUT = 3;
integer gLOCKMEISTER_CHANNEL		  = -8888;
integer gLOCKGUARD_CHANNEL			= -9119;

// particel
string  gTexture					  = "245ea72d-bc79-fee3-a802-8e73c0f09473";
float   gXsize						= 0.07;
float   gYsize						= 0.07;
float   gGravity					  = 0.03;
float   gLife						 = 1;
float   gRed						  = 1;
float   gGreen						= 1;
float   gBlue						 = 1;

// incomming link messages...
integer gCMD_SET_CHAINS			   = 2732; // cmdId, set chains in msg
integer gCMD_REM_CHAINS			   = 2733; // cmdId, remove all chains
integer gCMD_CONFIG				   = 2734; // cmdId, config in msg
string  gSET_SEPARATOR				= "~"; // separator from linkmessage

// timer
float   gControlTime				  = 15; // rescantimer, if leashpoints missing
integer gAddMode					  = 1;
integer gControlMode				  = 2;

// For trying to use lockguard as a fallback, you need to specify mappings here
// from the lockmeister to lockguard attachment IDs. I know that this is not
// perfect, since lockmeister and lockguard offer different cuff points and
// additionally work just the other way round. So I tried to do my best and
// give the best mapping I could think of. But you might need to change it,
// depending on your needs and piece of furniture.
// For reference and available points, see:
// http://wiki.secondlife.com/wiki/LSL_Protocol/LockMeister_System
// http://lslwiki.net/lslwiki/wakka.php?wakka=exchangeLockGuardItem
list   gLM_TO_LG_MAPPINGS = [
	"rcuff",	"rightwrist",
	"rbiceps",  "rightupperarm",
	"lbiceps",  "leftupperarm",
	"lcuff",	"leftwrist",
	"lblade",   "harnessleftloopback",  // ?
	"rblade",   "harnessrightloopback", // ?
	"rnipple",  "rightnipplering",
	"lnipple",  "leftnipplering",
	"rfbelt",   "rightbeltloop",
	"lfbelt",   "leftbeltloop",
	"rtigh",	"rightupperthigh",
	"ltigh",	"leftupperthigh",
	"rlcuff",   "rightankle",
	"llcuff",   "leftankle",
	"lbbelt",   "harnessleftloopback",  // ?
	"rbbelt",   "harnessrightloopback", // ?
	"pelvis",   "clitring",			 // ?
	"fbelt",	"frontbeltloop",
	"bbelt",	"backbeltloop",
	"rcollar",  "collarrightloop",
	"lcollar",  "collarleftloop",
	"thead",	"topheadharness",	   // ?
	"collar",   "collarfrontloop",
	"lbit",	 "leftgag",			  // ?
	"rbit",	 "rightgag",			 // ?
	"nose",	 "nosering",
	"bcollar",  "collarbackloop",
	"back",	 "harnessbackloop",	  // ?
	"lhand",	"leftwrist",			// ?
	"rhand",	"rightwrist"			// ?
];

// --- global variables ---
list	gPrimIDs;		 // description => linkId
list	gLmCalls;		 // store call-string => linkId for listen
integer gLmCallsLength;   // length of gLmCalls
integer gListenLMHandle;  // storing lockmeister listening handle
integer gListenLGHandle;  // storing lockguard listening handle
list	gSetChains;
list	gMissingChainPoints;
list	gParticles;
integer gTimerMode;

// ============================================================
list ListItemDelete(list mylist,string element_old) {
	integer placeinlist = llListFindList(mylist, [element_old]);
	if (placeinlist != -1)
		return llDeleteSubList(mylist, placeinlist, placeinlist);
	return mylist;
}

query_set_chains( key avatarKey, list items ) {
	integer itemLength = llGetListLength( items );

	if (gListenLMHandle == -1) gListenLMHandle = llListen( gLOCKMEISTER_CHANNEL, "", NULL_KEY, "" );
	if (gListenLGHandle == -1) gListenLGHandle = llListen( gLOCKGUARD_CHANNEL, "", NULL_KEY, "" );
	integer i;
	for( i=0; i < itemLength; i+=2 ) {
		string desc	= llList2String( items, i );
		integer index  = llListFindList( gPrimIDs, [ desc ] );
		if( index == -1 ) {
//			  llOwnerSay( "/me Error: no ring " + desc + " found" );
		}
		else {
			integer primId = llList2Integer( gPrimIDs, index + 1 );
			llLinkParticleSystem( primId, [] );
			string mooring = llList2String(  items,	i + 1 );
			if( mooring != "" ) {
//				llOwnerSay( "Chain: " + desc + " -> " + mooring
//					+ " PrimId: " + (string)primId );
				string lm_call = (string)avatarKey + mooring;
				// llOwnerSay( "Calling: " + lm_call );
				if( -1 == llListFindList( gLmCalls, [ lm_call + " ok" ] ) ) {
					llWhisper( gLOCKMEISTER_CHANNEL, lm_call );

					index = llListFindList( gLM_TO_LG_MAPPINGS, [ mooring ] );
					if( index != -1 ) {
						string lgMooring  = llList2String( gLM_TO_LG_MAPPINGS, index + 1 );
						key	 primKey   = llGetLinkKey( primId );
						llWhisper( gLOCKGUARD_CHANNEL, "lockguard " + (string)avatarKey + " " + lgMooring + " texture " + gTexture + " size " + (string)gXsize + " " + (string)gYsize + " gravity " + (string)gGravity + " color " + (string)gRed + " " + (string)gGreen + " " + (string)gBlue + " life " + (string)gLife + " link " + (string)primKey + " ping" );
						gSetChains += [ desc, avatarKey, mooring, lgMooring ];
					} else {
						gSetChains += [ desc, avatarKey, mooring, "-" ];
					}
					gLmCalls += [ lm_call + " ok", primId ];
					gMissingChainPoints += [desc];
				}
			}
		}   
	} // for i

	gLmCallsLength = llGetListLength( gLmCalls );
	gTimerMode = gAddMode;
	llSetTimerEvent( gLOCKMEISTER_RESPONSE_TIMEOUT );
}

query_rem_chains( key avatarKey, list descriptions ) {
	integer length = llGetListLength( descriptions );
	integer i;
	for( i=0; i < length; i+=1 ) {
		string description = llList2String( descriptions, i );
		// lockmeister
		integer index	  = llListFindList( gPrimIDs, [ description ] );
		if( index != -1 ) {
			llLinkParticleSystem( llList2Integer( gPrimIDs, index + 1 ), [] );
		}
		else {
//					llOwnerSay( "/me Error: no desc found: " + description );
		}
		//LockGuard
		index   = llListFindList( gSetChains, [ description ] );
		if( ~index ) {
			llWhisper( gLOCKGUARD_CHANNEL, "lockguard " + (string)llList2Key( gSetChains, index + 1 ) + " "
			+  llList2String( gSetChains, index + 3 ) + " unlink" );
			gSetChains = llDeleteSubList( gSetChains, index, index + 3 );
		}
		//remove attachpoint from the missing list
		gMissingChainPoints = ListItemDelete( gMissingChainPoints, description );				 
	}
}

update_chains() {
	if (gListenLMHandle == -1) gListenLMHandle = llListen( gLOCKMEISTER_CHANNEL, "", NULL_KEY, "" );
	if (gListenLGHandle == -1) gListenLGHandle = llListen( gLOCKGUARD_CHANNEL, "", NULL_KEY, "" );
	integer length = llGetListLength( gSetChains );
	integer i;
	for( i=0; i < length; i+=4 ) {
		string desc	= llList2String( gSetChains, i );
		integer index  = llListFindList( gPrimIDs, [ desc ] );
		integer primId = llList2Integer( gPrimIDs, index + 1 );
		
		//LM request
		string mooring = llList2String(  gSetChains, i + 2 );
		string lm_call = (string)llList2Key( gSetChains, i + 1 ) + mooring;
		llWhisper( gLOCKMEISTER_CHANNEL, lm_call );

		//LG request
		string lgMooring = llList2String(  gSetChains, i + 3 );
		if( lgMooring != "-" ) {
			key	 primKey   = llGetLinkKey( primId );
			llWhisper( gLOCKGUARD_CHANNEL, "lockguard " + (string)llList2Key( gSetChains, i + 1 ) + " " + lgMooring + " texture " + gTexture + " size " + (string)gXsize + " " + (string)gYsize + " gravity " + (string)gGravity + " life " + (string)gLife + " color " + (string)gRed + " " + (string)gGreen + " " + (string)gBlue + " link " + (string)primKey + " ping" );
		}
		gLmCalls += [ lm_call + " ok", primId ];
	}
	gLmCallsLength = llGetListLength( gLmCalls );
	gTimerMode = gAddMode;
	llSetTimerEvent( gLOCKMEISTER_RESPONSE_TIMEOUT );
}

control_chains() {
	if (gListenLMHandle == -1) gListenLMHandle = llListen( gLOCKMEISTER_CHANNEL, "", NULL_KEY, "" );
	if (gListenLGHandle == -1) gListenLGHandle = llListen( gLOCKGUARD_CHANNEL, "", NULL_KEY, "" );
	integer length = llGetListLength( gMissingChainPoints );
	integer i2;
	for( i2=0; i2 < length; i2+=1 ) {
		string desc	= llList2String( gMissingChainPoints, i2 );
		integer i	  = llListFindList( gSetChains, [ desc ] );
		integer index  = llListFindList( gPrimIDs, [ desc ] );
		integer primId = llList2Integer( gPrimIDs, index + 1 );
		
		//LM request
		string mooring = llList2String(  gSetChains, i + 2 );
		string lm_call = (string)llList2Key( gSetChains, i + 1 ) + mooring;
		llWhisper( gLOCKMEISTER_CHANNEL, lm_call );

		//LG request
		string lgMooring = llList2String(  gSetChains, i + 3 );
		if( lgMooring != "-" ) {
			key	 primKey   = llGetLinkKey( primId );
			llWhisper( gLOCKGUARD_CHANNEL, "lockguard " + (string)llList2Key( gSetChains, i + 1 ) + " " + lgMooring + " texture " + gTexture + " size " + (string)gXsize + " " + (string)gYsize + " gravity " + (string)gGravity + " life " + (string)gLife + " color " + (string)gRed + " " + (string)gGreen + " " + (string)gBlue + " link " + (string)primKey + " ping" );
		}
		gLmCalls += [ lm_call + " ok", primId ];
	}
	gLmCallsLength = llGetListLength( gLmCalls );
	gTimerMode = gAddMode;
	llSetTimerEvent( gLOCKMEISTER_RESPONSE_TIMEOUT );
}

query_config( key avatarKey, list items ) {
	integer length = llGetListLength( items );
	integer i;
	for( i=0; i < length; i+=1 ) {
		list line = llParseString2List( llList2String( items, i ), ["="], [] );
		string item = llList2String( line, 0 );
		
		if ( item == "texture" )	  gTexture = llList2String( line, 1 );
		else if ( item == "xsize" )   gXsize   = llList2Float( line, 1 );
		else if ( item == "ysize" )   gYsize   = llList2Float( line, 1 );
		else if ( item == "gravity" ) gGravity = llList2Float( line, 1 );
		else if ( item == "life" )	gLife	= llList2Float( line, 1 );
		else if ( item == "red" )	 gRed	 = llList2Float( line, 1 );
		else if ( item == "green" )   gGreen   = llList2Float( line, 1 );
		else if ( item == "blue" )	gBlue	= llList2Float( line, 1 );
	}
	set_particle();
	update_chains();
}

set_particle() {
	gParticles = [  // start of particle settings
					PSYS_PART_START_SCALE,	 <gXsize, gYsize, FALSE>,
					PSYS_PART_END_SCALE,	   <gXsize, gYsize, FALSE>,
					PSYS_PART_MAX_AGE,		 gLife,
					PSYS_SRC_ACCEL,			<0, 0, (gGravity*-1)>,		
					PSYS_SRC_TEXTURE,		  gTexture, 
					PSYS_SRC_PATTERN,		  PSYS_SRC_PATTERN_DROP,		
					PSYS_SRC_BURST_PART_COUNT, 2,
					PSYS_SRC_BURST_RATE,	   0.1,
					PSYS_PART_START_COLOR,	 <gRed, gGreen, gBlue>,
					PSYS_PART_END_COLOR,	   <gRed, gGreen, gBlue>, 
					PSYS_PART_FLAGS,
						PSYS_PART_FOLLOW_VELOCITY_MASK |
						PSYS_PART_FOLLOW_SRC_MASK |
						PSYS_PART_TARGET_POS_MASK |
						PSYS_PART_INTERP_SCALE_MASK
				];
}
// ============================================================
default {
	state_entry() {
		gPrimIDs = [];
		gSetChains = [];
		gLmCalls = [];
		gListenLMHandle = -1;
		gListenLGHandle = -1;
		integer number_of_prims = llGetNumberOfPrims();
		integer i;
		for( i=1; i < number_of_prims + 1; ++i ) { 
			string desc = llList2String( llGetLinkPrimitiveParams( i, [ PRIM_DESC ] ), 0 );
			if( desc != "" && desc != "(No description)" ) {
				if( -1 == llListFindList( gPrimIDs, [ desc ] ) ) { // only accept unique descriptions
					gPrimIDs += [ desc, i ];
				}
				else {
					llOwnerSay( "/me Error: prim description " + desc
						+ " isn't unique, please make it unique... ignoring" );  
				}
			}
		}
		set_particle();
//	  gPrimIDs = llListSort( gPrimIDs, 2, TRUE );
//	  llOwnerSay( "PrimIDs: " + llDumpList2String( gPrimIDs, "\t" ) );
	}

	link_message( integer primId, integer commandId, string message, key avatarKey ) {

		if( commandId == gCMD_REM_CHAINS ) {	
			query_rem_chains( avatarKey,
				llParseStringKeepNulls( message, [ gSET_SEPARATOR ], [] )
			);
		}
		else if( commandId == gCMD_SET_CHAINS ) {
			query_set_chains( avatarKey,
				llParseStringKeepNulls( message, [ gSET_SEPARATOR ], [] )
			);					
		}
		else if( commandId == gCMD_CONFIG ) {
			query_config( avatarKey,
				llParseStringKeepNulls( message, [ gSET_SEPARATOR ], [] )
			);					
		}
	}
	
	listen( integer channel, string cuffName, key cuffKey, string message ) {
		if( channel == gLOCKGUARD_CHANNEL ) {
			list s = llParseStringKeepNulls( message, [ " " ], [] );
			key avatar = llList2Key( s, 1 );
			string lgmooring = llList2String( s , 2 );
			integer index = llListFindList( gLM_TO_LG_MAPPINGS, [ lgmooring ] );
			if( index != -1 ) {
				string mooring  = llList2String( gLM_TO_LG_MAPPINGS, index - 1 );
				string lm_call = (string)avatar + mooring + " ok";
				integer i = llListFindList( gLmCalls, (list)lm_call );
				if( ~i ) {
					integer i2 = llListFindList( gPrimIDs , [ llList2Integer( gLmCalls, i + 1 ) ] );
					string desc = llList2String( gPrimIDs,  i2 - 1  );
					gMissingChainPoints = ListItemDelete( gMissingChainPoints, desc );				 
				}
			}
		}
		else if( channel == gLOCKMEISTER_CHANNEL ) {
			integer i;
		
			if( llGetSubString( message, -2, -1 ) == "ok" ) {//it's an old style v1 LM reply
				i = llListFindList( gLmCalls, (list)message );//check it's a point on the list
				if( ~i ) {
					//Lockguard remove, because Lockmeister is found
					integer index = llListFindList( gLM_TO_LG_MAPPINGS, [ llGetSubString( message, 36, -4 ) ] );
					llWhisper( gLOCKGUARD_CHANNEL, "lockguard " + llGetSubString( message, 0, 35 ) + " " + llList2String( gLM_TO_LG_MAPPINGS, index + 1 ) + " unlink ");
					// send lockmeister chain
					llLinkParticleSystem( llList2Integer( gLmCalls, i + 1 ), gParticles + [ PSYS_SRC_TARGET_KEY, cuffKey ] );
					//now send a v2 style LM message, because if the target attachment is using v2 style messages,
					// then the chains will be better targetted
					llRegionSayTo( (key)llGetSubString( message, 0, 35 ), gLOCKMEISTER_CHANNEL, llGetSubString( message, 0, 35 ) +"|LMV2|RequestPoint|" + llGetSubString( message, 36, -4 ) );
					gTimerMode = gAddMode;
					llSetTimerEvent( gLOCKMEISTER_RESPONSE_TIMEOUT );
					//remove point from the gMissingChainPoints List
					integer i2 = llListFindList( gPrimIDs , [ llList2Integer( gLmCalls, i + 1 ) ] );
					string desc = llList2String( gPrimIDs,  i2 - 1  );
					gMissingChainPoints = ListItemDelete( gMissingChainPoints, desc );				 
				}
			}
			else { //v2 style LM reply
				// is it a v2 style LM reply?
				list temp = llParseString2List( message, ["|"], [""] );
				if( llList2String( temp, 1 ) == "LMV2" && llList2String( temp, 2 ) == "ReplyPoint" ) {	//looks like it is
					//check it's a point on the list
					i = llListFindList( gLmCalls, (list)( llList2String( temp, 0 ) + llList2String( temp, 3 ) + " ok" ) );
					if( ~i ) {
						// send lockmeister chain
						llLinkParticleSystem( llList2Integer( gLmCalls, i + 1 ), gParticles + [ PSYS_SRC_TARGET_KEY, (key)llList2String( temp, 4 ) ] );
					}
				}
			}
		}
	}

	timer() {
		
		if ( gTimerMode == gAddMode ) {
			llSetTimerEvent( 0.0 );
			llListenRemove( gListenLMHandle );
			gListenLMHandle = -1;
			llListenRemove( gListenLGHandle );
			gListenLGHandle = -1;
				
			// cleanup
			gLmCalls = [];
			
			if ( llGetListLength(gMissingChainPoints) ) {
				gTimerMode = gControlMode;
				llSetTimerEvent( gControlTime );
			}
		}
		else if ( gTimerMode == gControlMode ) {
			if ( llGetListLength( gMissingChainPoints ) ) {
				control_chains();
			}
			else llSetTimerEvent( 0.0 );
		}
	}
	
	on_rez(integer param) {
		llResetScript();
	}
	
} // default
// ============================================================
