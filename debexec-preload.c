#define _GNU_SOURCE

#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <dlfcn.h>

int _debexec_uidmap(void)
{
    static int using_uidmap = -1;

    if (using_uidmap != -1) return using_uidmap;
    using_uidmap = atoi(getenv("DEBEXEC_UIDMAP"));
    return using_uidmap;
}
#define debexec_uidmap _debexec_uidmap()

int chown(const char *pathname, uid_t owner, gid_t group)
{
    static typeof(chown) *real_chown = NULL;

#ifdef DEBUG
    fprintf(stderr, "called chown(%s, %d %d)\n", pathname, owner, group);
#endif
    if (strncmp(pathname, "/dev/pts", sizeof("/dev/pts")-1) == 0) return 0;
    if (!debexec_uidmap)
    {
        if (owner != 0) owner = 0;
        if (group != 0) group = 0;
    }

    if (!real_chown) real_chown = dlsym(RTLD_NEXT, "chown");
    return real_chown(pathname, owner, group);
}

int fchown(int fd, uid_t owner, gid_t group)
{
    static typeof(fchown) *real_fchown = NULL;

#ifdef DEBUG
    fprintf(stderr, "called fchown(%d, %d %d)\n", fd, owner, group);
#endif
    if (!debexec_uidmap)
    {
        if (owner != 0) owner = 0;
        if (group != 0) group = 0;
    }

    if (!real_fchown) real_fchown = dlsym(RTLD_NEXT, "fchown");
    return real_fchown(fd, owner, group);
}

int fchownat(int dirfd, const char *pathname, uid_t owner, gid_t group, int flags)
{
    static typeof(fchownat) *real_fchownat = NULL;

#ifdef DEBUG
    fprintf(stderr, "called fchownat(%d, %s, %d, %d, %d)\n", dirfd, pathname, owner, group, flags);
#endif
    if (!debexec_uidmap)
    {
        if (owner != 0) owner = 0;
        if (group != 0) group = 0;
    }

    if (!real_fchownat) real_fchownat = dlsym(RTLD_NEXT, "fchownat");
    return real_fchownat(dirfd, pathname, owner, group, flags);
}

int setxattr(const char *path, const char *name, const void *value, size_t size, int flags)
{
    static typeof(setxattr) *real_setxattr = NULL;

#ifdef DEBUG
    fprintf(stderr, "called setxattr(%s, %s, [call specific], %d, %d)\n", path, name, size, flags);
#endif
    if (!debexec_uidmap)
    {
        if (strcmp(name, "system.posix_acl_access") == 0) return 0;
        if (strcmp(name, "system.posix_acl_default") == 0) return 0;
    }

    if (!real_setxattr) real_setxattr = dlsym(RTLD_NEXT, "setxattr");
    return real_setxattr(path, name, value, size, flags);
}

int seteuid(uid_t euid)
{
    static typeof(seteuid) *real_seteuid = NULL;

#ifdef DEBUG
    fprintf(stderr, "called seteuid(%d)\n", euid);
#endif
    if (!debexec_uidmap && euid != 0) return 0;

    if (!real_seteuid) real_seteuid = dlsym(RTLD_NEXT, "seteuid");
    return real_seteuid(euid);
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

int setresuid(uid_t ruid, uid_t euid, uid_t suid) {
    static typeof(setresuid) *real_setresuid = NULL;

#ifdef DEBUG
    fprintf(stderr, "called setresuid(%d, %d, %d)\n", ruid, euid, suid);
#endif
    if (!debexec_uidmap)
    {
        if (ruid != 0) ruid = -1;
        if (euid != 0) euid = -1;
        if (suid != 0) suid = -1;
    }

    if (!real_setresuid) real_setresuid = dlsym(RTLD_NEXT, "setresuid");
    return real_setresuid(ruid, euid, suid);
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
