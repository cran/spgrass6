% Copyright (C) 2005-2012 Roger S. Bivand
\name{readRAST}
\alias{readRAST}
\alias{readRAST6}
\alias{writeRAST}
\alias{writeRAST6}
\title{Read and write GRASS 6+ raster files}
\description{
Read GRASS 6+ raster files from GRASS 6+ into R SpatialGridDataFrame
objects, and write single columns of R SpatialGridDataFrame objects to
GRASS 6+. \code{readRAST} and \code{writeRAST} use temporary binary
files and r.out.bin and r.in.bin rather than the temporary ASCII files
used in earlier implementations. The earlier versions may still be used
in a transition period.
The functions \code{readRAST} and \code{readRAST6} as well as \code{writeRAST}
and \code{writeRAST6} are identical and the functions ending with
\code{...6} are maintained only for backward compatibility and might be deprecated.
}



\usage{
readRAST(vname, cat=NULL, ignore.stderr = NULL, NODATA=NULL, plugin=NULL,
 mapset=NULL, useGDAL=NULL, close_OK=TRUE, drivername="GTiff",
 driverFileExt=NULL, return_SGDF=TRUE)
writeRAST(x, vname, zcol = 1, NODATA=NULL, ignore.stderr = NULL,
 useGDAL=NULL, overwrite=FALSE, flags=NULL, drivername="GTiff")
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{vname}{A vector of GRASS 6.0 raster file names}
  \item{cat}{default NULL; if not NULL, must be a logical vector matching vname, stating which (CELL) rasters to return as factor}
  \item{ignore.stderr}{default NULL, taking the value set by \code{set.ignore.stderrOption}, can be set to TRUE to silence \code{system()} output to standard error; does not apply on Windows platforms}
  \item{plugin}{default NULL does auto-detection, changes to FALSE if vname is longer than 1, and a sanity check will be run on raster and current region, and the function will revert to FALSE if mismatch is found; if TRUE, the plugin is available and the raster should be read in its original region and resolution; if the plugin is used, no further arguments other than mapset are respected}
  \item{mapset}{default NULL, if plugin is TRUE, the mapset of the file to be imported will be autodetected; if not NULL and if plugin is TRUE, a character string overriding the autodetected mapset, otherwise ignored}
  \item{useGDAL}{default NULL, taking the value set by \code{set.useGDALOption}; use r.out.gdal or plugin and \code{readGDAL} if autodetected or plugin=TRUE; or for writing \code{writeGDAL}, GTiff, and r.in.gdal, if FALSE using r.out.bin or r.in.bin}
  \item{close_OK}{default TRUE - clean up possible open connections used for reading metadata; may be set to FALSE to avoid the side-effect of other user-opened connections being broken}
  \item{drivername}{default \code{"GTiff"}; a valid GDAL writable driver name to define the file format for intermediate files}
  \item{driverFileExt}{default NULL; otherwise string value of required driver file name extension}
  \item{return_SGDF}{default TRUE returning a \code{SpatialGridDataFrame} object, if FALSE, return a list with a \code{GridTopology} object, a list of bands, and a proj4string; see example below}
  \item{x}{A SpatialGridDataFrame object for export to GRASS as a raster layer}
  \item{zcol}{Attribute column number or name}
  \item{NODATA}{by default NULL, in which case it is set to one less than \code{floor()}of the data values, otherwise an integer NODATA value (required to be integer by GRASS r.out.bin)}
  \item{overwrite}{default FALSE, if TRUE inserts \code{"overwrite"} into the value of the \code{flags} argument if not already there to allow existing GRASS rasters to be overwritten}
  \item{flags}{default NULL, character vector, for example \code{"overwrite"}}
%  \item{colname}{alternative name for data column if not file basename}
%  \item{integer}{logical value: TRUE if the input data is integer}
}

\value{
\code{readRAST} returns a SpatialGridDataFrame objects with an data.frame in the data slots, and with the projection argument set. Note that the projection argument set is the the GRASS rendering of proj4, and will differ from the WKT/ESRI rendering returned by \code{readVECT} in form but not meaning. They are exchangeable but not textually identical, usually with the +ellps= term replaced by ellipsoid parameters verbatim. If return_SGDF is FALSE, a list with a \code{GridTopology} object, a list of bands, and a proj4string is returned, with an S3 class attribute of \dQuote{gridList}.
}


\author{Roger S. Bivand, e-mail: \email{Roger.Bivand@nhh.no}}

\examples{
if (nchar(Sys.getenv("GISRC")) > 0) {
  require(rgdal)
  ois <- get.ignore.stderrOption()
  set.ignore.stderrOption(TRUE)
  get.useGDALOption()
  spear <- readRAST(c("geology", "elevation.dem"), cat=c(TRUE, FALSE),
    useGDAL=FALSE)
  spear <- readRAST(c("geology", "elevation.dem"), cat=c(TRUE, FALSE),
    useGDAL=TRUE)
  print(table(spear$geology))
  execGRASS("r.stats", flags=c("c", "l", "quiet"), input="geology")
  boxplot(spear$elevation.dem ~ spear$geology)
  spear$sqdem <- sqrt(spear$elevation.dem)
  if ("GRASS" \%in\% gdalDrivers()$name) {
    execGRASS("g.region", rast="elevation.dem")
    dem1 <- readRAST("elevation.dem", plugin=TRUE, mapset="PERMANENT")
    print(summary(dem1))
    execGRASS("g.region", rast="elevation.dem")
  }
  writeRAST(spear, "sqdemSP", zcol="sqdem")
  execGRASS("r.info", map="sqdemSP")
  execGRASS("g.remove", rast="sqdemSP")
  writeRAST(spear, "sqdemSP", zcol="sqdem", useGDAL=TRUE)
  execGRASS("r.info", map="sqdemSP")
  print(system.time(sqdemSP <- readRAST(c("sqdemSP", "elevation.dem"),
    useGDAL=TRUE, return_SGDF=FALSE)))
  print(system.time(sqdemSP <- readRAST(c("sqdemSP", "elevation.dem"),
    useGDAL=TRUE, return_SGDF=TRUE)))
  print(system.time(sqdemSP <- readRAST(c("sqdemSP", "elevation.dem"),
    useGDAL=FALSE, return_SGDF=TRUE)))
  print(system.time(sqdemSP <- readRAST(c("sqdemSP", "elevation.dem"),
    useGDAL=FALSE, return_SGDF=FALSE)))
  str(sqdemSP)
  mat <- do.call("cbind", sqdemSP$dataList)
  str(mat)
  print(system.time(SGDF <- SpatialGridDataFrame(grid=sqdemSP$grid,
    proj4string=sqdemSP$proj4string, data=as.data.frame(sqdemSP$dataList))))
  summary(SGDF)
  execGRASS("g.remove", rast="sqdemSP")
  if (execGRASS("g.version", intern=TRUE) > "GRASS 7") {
    execGRASS("r.mapcalc", expression="quads0 = quads - 1")
  } else {
    execGRASS("r.mapcalculator", outfile="quads0",
      amap="quads", formula='A - 1')
  }
  execGRASS("r.stats", flags="c", input="quads0")
  quads0 <- readRAST("quads0")
  print(table(quads0$quads0))
  quads0 <- readRAST("quads0", plugin=FALSE)
  print(table(quads0$quads0))
  execGRASS("g.remove", rast="quads0")
  set.ignore.stderrOption(ois)
}
}
\keyword{spatial}

