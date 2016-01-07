arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg

target ?= $(arch)-unknown-linux-gnu
rust_os := target/$(target)/debug/libblog_os.a

assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
    build/arch/$(arch)/%.o, $(assembly_source_files))

.PHONY: all clean kernel test iso run

all: kernel

clean:
	rm -r build
	cargo clean

test:
	echo $(assembly_source_files)


kernel: $(kernel)

iso: $(iso)

run: $(iso)
	qemu-system-x86_64 -cdrom $(iso) -curses # curses because I am running in nongraphical vagrant vm

$(kernel): cargo $(assembly_object_files) $(linker_script)
	ld -n --gc-sections -o $(kernel) -T $(linker_script) $(assembly_object_files) $(rust_os)

cargo:
	cargo rustc --target $(target) -- -Z no-landing-pads -C no-redzone

build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	mkdir -p $(shell dirname $@)
	nasm -felf64 $< -o $@

$(iso): $(kernel) $(grub_cfg)
	mkdir -p build/isofiles/boot/grub
	cp $(kernel) build/isofiles/boot/kernel.bin
	cp $(grub_cfg) build/isofiles/boot/grub
	grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	rm -r build/isofiles
