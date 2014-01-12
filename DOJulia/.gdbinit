fb [NSException raise]
fb _NXRaiseError

dir ../../OmniFoundation
dir ../../OmniAppkit
dir ../../OmniDocument
dir ../Shared

source PB.gdbinit

printf "\n\n****** Enabling zombies! ******\n\n\n"
set env NSZombieEnabled=YES
set env NSDeallocZombies=NO
fb [_NSZombie forwardInvocation:]
