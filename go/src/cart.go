package main

import (
	"errors"
	"io/ioutil"
)

type Cart struct {
	data             []byte
	logo             []byte
	name             string
	is_gbc           bool
	licensee         int
	is_sgb           bool
	cart_type        int // CartType
	rom_size         int
	ram_size         int
	destination      int // Destination
	old_licensee     int // OldLicensee
	rom_version      int
	complement_check int
	checksum         int
}

const KB = 1024

func parse_rom_size(val uint8) uint32 {
	return (32 * KB) << val;
}

func parse_ram_size(val uint8) uint32 {
	switch val {
	case 0:
		return 0
	case 2:
		return 8 * KB
	case 3:
		return 32 * KB
	case 4:
		return 128 * KB
	case 5:
		return 64 * KB
	default:
		return 0
	}
}

func NewCart(rom string) (*Cart, error) {
	var data, err = ioutil.ReadFile(rom)
	if err != nil {
		return nil, err
	}

	var logo = data[0x0104 : 0x0104+48]
	var name = data[0x0134 : 0x0134+16]
	var is_gbc = data[0x143] == 0x80 // 0x80 = works on both, 0xC0 = colour only
	var licensee = uint16(data[0x144])<<8 | uint16(data[0x145])
	var is_sgb = data[0x146] == 0x03
	var cart_type = data[0x147]
	var rom_size = parse_rom_size(data[0x148])
	var ram_size = parse_ram_size(data[0x149])
	var destination = data[0x14A]
	var old_licensee = data[0x14B]
	var rom_version = data[0x14C]
	var complement_check = data[0x14D]
	var checksum = uint16(data[0x14E])<<8 | uint16(data[0x14F])

	var logo_checksum uint16 = 0
	for i := range logo {
		logo_checksum += uint16(logo[i])
	}
	if logo_checksum != 5446 {
		return nil, errors.New("Logo checksum failed")
	}

	var header_checksum uint16 = 25
	for i := 0x0134; i < 0x014E; i++ {
		header_checksum += uint16(data[i])
	}
	if (header_checksum & 0xFF) != 0 {
		return nil, errors.New("Header checksum failed")
	}

	return &Cart{
		data,
		logo,
		string(name),
		is_gbc,
		int(licensee),
		is_sgb,
		int(cart_type),
		int(rom_size),
		int(ram_size),
		int(destination),
		int(old_licensee),
		int(rom_version),
		int(complement_check),
		int(checksum),
	}, nil
}
