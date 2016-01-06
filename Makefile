
kernel := build/kernel.bin
linker_script := src/asm/linker.ld

grub_cfg := src/grub.cfg
isofiles := build/isofiles/boot/grub
iso := build/os.iso

assembly_source_files := $(wildcard src/asm/*.asm)
assembly_object_files := $(patsubst src/asm/%.asm, \
	build/asm/%.o, $(assembly_source_files))

.PHONY: clean kernel test iso run

clean:
	rm -r build

test:
	echo $(assembly_source_files)

kernel: $(kernel)

iso: $(iso)

run:
	qemu-system-x86_64 -cdrom @(iso) -curses # curses because I am running in nongraphical vagrant vm

$(kernel): $(assembly_object_files)
	ld -n -o build/kernel.bin -T $(linker_script) $(assembly_object_files)

build/asm/%.o: src/asm/%.asm
	mkdir -p $(shell dirname $@)
	nasm -felf64 $< -o $@

$(iso): $(kernel)
	mkdir -p $(isofiles)
	cp $(kernel) build/isofiles/boot
	cp $(grub_cfg) $(isofiles)
	grub-mkrescue -o build/os.iso build/isofiles
	rm -r build/isofiles
