#define _GNU_SOURCE

#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <dlfcn.h>

int chown(const char *pathname, uid_t owner, gid_t group)
{
    static typeof(chown) *real_chown = NULL;

#ifdef DEBUG
    fprintf(stderr, "called chown(%s, %d %d)\n", pathname, owner, group);
#endif
    if (strncmp(pathname, "/dev/pts", sizeof("/dev/pts")-1) == 0) return 0;

    if (!real_chown) real_chown = dlsym(RTLD_NEXT, "chown");
    return real_chown(pathname, owner, group);
}

int setegid(gid_t egid)
{
    static typeof(setegid) *real_setegid = NULL;

#ifdef DEBUG
    fprintf(stderr, "called setegid(%d)\n", egid);
#endif
    if (egid == 0 || egid == 65534) return 0;

    if (!real_setegid) real_setegid = dlsym(RTLD_NEXT, "setegid");
    return real_setegid(egid);
}

int setresgid(gid_t rgid, gid_t egid, gid_t sgid) {
    static typeof(setresgid) *real_setresgid = NULL;

#ifdef DEBUG
    fprintf(stderr, "called setresgid(%d, %d, %d)\n", rgid, egid, sgid);
#endif
    if (rgid == 65534) rgid = -1;
    if (egid == 65534) egid = -1;
    if (sgid == 65534) sgid = -1;

    if (!real_setresgid) real_setresgid = dlsym(RTLD_NEXT, "setresgid");
    return real_setresgid(rgid, egid, sgid);
}

int setgroups(int size, gid_t list[]) {
    return 0;
}
