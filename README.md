# nPose LM/LG chains plugin
based on `plugin_lockmeister_lockguard v0.01` written by xandrinex

modified by pfil payne

## History

`nPose LM/LG chains plugin v0.04`
- allow the rootprim to be a leashpoint

`nPose LM/LG chains plugin v0.02`
- made the plugin usable for more then one victim
- added LMv2 compatibility
- scan for leashpoints (cuffs that are attached after the initial particle command will be recognized)
- added particle config

`plugin_lockmeister_lockguard v0.01`
- Removed some of the error reporting to allow this plugin to be used in prim chain points without errors.

## Setup
### Chains in the main build
1.  Include the `nPose LM/LG chains plugin` script in the main build.
2.  Add the chain points also to the build.
3.  Make the description of each chain point unique so they can be referred to in nPose notecard.
4.  Make a `SET` card and use `SATMSG` for telling the plugin to send chains and where they should go when someone sits this seat.  
`SATMSG` in this form: `SATMSG|2732|leftloop~lcuff~rightloop~rcuff`
  1. The arb num 2732 is what the chains plugin is looking for and is interpreted as a command to send chains.
  2. The next is a list of chain point~cuff point matching pairs.  In the above `SATMSG` the pairs are as follows:  leftloop to lcuff, and rightloop to rcuff.
  3. Chains are drawn from the chain point to the designated cuff (or vice versa). See references below for a list of cahin point names.
5. Add a `NOTSATMSG` to drop chains when this person stands or changes pose sets.  
  NOTSATMSG in this form: `SATMSG|2733|leftloop~rightloop`
  1. The arb num 2733 is what the chains plugin is looking for and is interpreted as a command to stop chains.
  2. The next is a list of chain point.  In the above `NOTSATMSG` the plugin simply stops the chains at the chain points listed.

### Chains in Props
1. Include the `nPose LM/LG chains plugin` script in each prop intended to be used for chain points along with the prop plugin `nPose prop 0.1 (2.0 verified)`.
2. Add the chain points also to the props if not using the root prim of the prop as the chain point.
3. Make the description of each chain point unique so they can be referred to in nPose notecard.
4. Make a `SET` card and use `SATMSG` for telling the plugin to send chains and where they should go when someone sits this seat.  
`SATMSG` in this form: `SATMSG|2732|leftloop~lcuff~rightloop~rcuff`
  1. The arb num 2732 is what the chains plugin is looking for and is interpreted as a command to send chains.
  2. The next is a list of chain point~cuff point matching pairs. In the above `SATMSG` the pairs are as follows:  leftloop to lcuff, and rightloop to rcuff.
  3. Chains are drawn from the chain point to the designated cuff (or vice versa). See references below for a list of cahin point names.
5. Add a `NOTSATMSG` to drop chains when this person stands or changes pose sets.  
  `NOTSATMSG` in this form: `SATMSG|2733|leftloop~rightloop`
  1. The arb num 2733 is what the chains plugin is looking for and is interpreted as a command to stop chains.
  2. The next is a list of chain point.  In the above `NOTSATMSG` the plugin simply stops the chains at the chain points listed.
6. Be sure to add the appropriate `PROP` lines in the `SET` card to rez these chain point props.

### Particle Config
1. Add a LINKMSG line:
LINKMSG|2734|Parameter (Comma separated)

With Parameters:
- `texture=`particle texture as uuid
- `xsize=`particle X size as float (0.03125 to 4.0)
- `ysize=`particle Y size as float (0.03125 to 4.0)
- `gravity=`particle gravity as float
- `life=`particle life time as float in seconds
- `red=` red part of the particle color as float (0 to 1)
- `green=` green part of the particle color as float (0 to 1)
- `blue=` blue part of the particle color as float (0 to 1)

## Notes
This Plugin is expecting all Prim Descriptions to be unique. It will warn the owner when any are not unique. If the description isn't used as a Leash Point Name the warning can be ignored.

## References for chain points:
http://wiki.secondlife.com/wiki/LSL_Protocol/LockMeister_System  
http://lslwiki.net/lslwiki/wakka.php?wakka=exchangeLockGuardItem
