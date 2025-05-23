#========================================================================
#
# xpdf/cmake-xpdf.txt
#
# CMake script for the Xpdf tools.
#
# Copyright 2015 Glyph & Cog, LLC
#
#========================================================================

include_directories("${PROJECT_SOURCE_DIR}")
include_directories("${PROJECT_BINARY_DIR}")
include_directories("${PROJECT_SOURCE_DIR}/goo")
include_directories("${PROJECT_SOURCE_DIR}/fofi")
include_directories("${PROJECT_SOURCE_DIR}/splash")
if (PNG_FOUND)
  include_directories("${PNG_INCLUDE_DIRS}")
  add_definitions("${PNG_DEFINITIONS}")
endif ()
if (HAVE_LCMS)
  include_directories("${LCMS_INCLUDE_DIR}")
  set(COLOR_MANAGER_SOURCE "ColorManager.cc")
else ()
  set(COLOR_MANAGER_SOURCE "")
endif ()

add_library(xpdf_objs OBJECT
  AcroForm.cc
  Annot.cc
  Array.cc
  BuiltinFont.cc
  BuiltinFontTables.cc
  Catalog.cc
  CharCodeToUnicode.cc
  CMap.cc
  ${COLOR_MANAGER_SOURCE}
  Decrypt.cc
  Dict.cc
  Error.cc
  FontEncodingTables.cc
  Form.cc
  Function.cc
  Gfx.cc
  GfxFont.cc
  GfxState.cc
  GlobalParams.cc
  JArithmeticDecoder.cc
  JBIG2Stream.cc
  JPXStream.cc
  Lexer.cc
  Link.cc
  NameToCharCode.cc
  Object.cc
  OptionalContent.cc
  Outline.cc
  OutputDev.cc
  Page.cc
  Parser.cc
  PDFDoc.cc
  PDFDocEncoding.cc
  PSTokenizer.cc
  SecurityHandler.cc
  Stream.cc
  TextString.cc
  UnicodeMap.cc
  UnicodeTypeTable.cc
  UTF8.cc
  XFAForm.cc
  XRef.cc
  Zoox.cc
)

#--- object files needed by XpdfWidget

if ((QT4_FOUND OR Qt5Widgets_FOUND)
    AND HAVE_SPLASH AND MULTITHREADED AND USE_EXCEPTIONS)

  if (HIGHLIGHTED_REGIONS)
    set(HIGHLIGHT_SRC "HighlightFile.cc")
  else ()
    set(HIGHLIGHT_SRC "")
  endif ()

  add_library(xpdf_widget_objs OBJECT
    DisplayState.cc
    PDFCore.cc
    PreScanOutputDev.cc
    PSOutputDev.cc
    SplashOutputDev.cc
    TextOutputDev.cc
    TileCache.cc
    TileCompositor.cc
    TileMap.cc
    ${HIGHLIGHT_SRC}
  )
endif ()


#--- pdftotext

add_executable(pdftotext
  $<TARGET_OBJECTS:xpdf_objs>
  TextOutputDev.cc
  pdftotext.cc
)

target_link_libraries(pdftotext goo fofi ${LCMS_LIBRARY} -fsanitize=fuzzer)
install(TARGETS pdftotext RUNTIME DESTINATION bin)
install(FILES ${PROJECT_SOURCE_DIR}/doc/pdftotext.1 DESTINATION man/man1)


