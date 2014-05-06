// We use 9-bit directions rather than 4-bit, in order to
// properly handle diagonals and UP.
#define PWR_NORTH     1
#define PWR_SOUTH     2
#define PWR_EAST      4
#define PWR_WEST      8
#define PWR_NORTHWEST 16
#define PWR_NORTHEAST 32
#define PWR_SOUTHWEST 64
#define PWR_SOUTHEAST 128
#define PWR_UP        256

var/list/all_netdirs = list(
	PWR_NORTH,
	PWR_SOUTH,
	PWR_WEST,
	PWR_EAST,
	PWR_NORTHWEST,
	PWR_NORTHEAST,
	PWR_SOUTHWEST,
	PWR_SOUTHEAST
)

/proc/pwrdir2dir(var/powerdir)
	switch(powerdir)
		if(PWR_NORTH)     return NORTH
		if(PWR_SOUTH)     return SOUTH
		if(PWR_WEST)      return WEST
		if(PWR_EAST)      return EAST
		if(PWR_NORTHWEST) return NORTHWEST
		if(PWR_NORTHEAST) return NORTHEAST
		if(PWR_SOUTHWEST) return SOUTHWEST
		if(PWR_SOUTHEAST) return SOUTHEAST
		if(PWR_UP)        return UP
	return null

/proc/dir2pwrdir(var/dir)
	switch(dir)
		if(NORTH)     return PWR_NORTH
		if(SOUTH)     return PWR_SOUTH
		if(WEST)      return PWR_WEST
		if(EAST)      return PWR_EAST
		if(NORTHWEST) return PWR_NORTHWEST
		if(NORTHEAST) return PWR_NORTHEAST
		if(SOUTHWEST) return PWR_SOUTHWEST
		if(SOUTHEAST) return PWR_SOUTHEAST
		if(UP)        return PWR_UP
		if(DOWN)      return PWR_UP
	return null
