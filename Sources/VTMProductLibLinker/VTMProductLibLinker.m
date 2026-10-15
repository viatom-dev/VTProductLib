//
//  VTMProductLibLinker.m
//
//  Intentionally (almost) empty. See include/VTMProductLibLinker.h and Package.swift.
//
//  SwiftPM requires a non-binary target to contain at least one source file, so this
//  file provides a single unused symbol rather than nothing at all — an entirely empty
//  translation unit is legal but trips "no symbols" warnings in some linker setups.
//

#import "include/VTMProductLibLinker.h"

__attribute__((used)) static const char VTMProductLibLinkerVersion[] = "link-only";
