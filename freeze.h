int			load_frozen_grammar(char	*path);
int			setup_save_frozen_grammar(char	*path);
void		reserve_freezer_address_space();
int			load_grammar();
int			freeze_grammar();
void		dump_grammar();
void		reload_frozen_grammar();
char		*freeze_string(char	*str);
wchar_t		*freeze_wcs(wchar_t	*str);
void		*freeze_block(void	*src, int	len);
struct dg	*freeze_dg(struct dg	*dg);

extern long	loaded_freeze_size;

//#define	FREEZER_MMAP_BASE	0x60000000
#ifdef	__aarch64__
// 0x6000000000 isn't mappable on Apple Silicon (reserved by the OS,
// EPERM on MAP_FIXED there); 0x7000000000 is free and is in fact where
// the kernel silently redirects the 0x6000000000 hint anyway.
#define	FREEZER_MMAP_BASE	0x7000000000L
#else
#define	FREEZER_MMAP_BASE	0x6000000000L
#endif

#define	FROZEN(x)		((long)x>=FREEZER_MMAP_BASE && (long)x<(FREEZER_MMAP_BASE+loaded_freeze_size))
