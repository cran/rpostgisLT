% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{pgTrajTempT}
\alias{pgTrajTempT}
\title{Creates a temporary table in the 'traj' schema.}
\usage{
pgTrajTempT(conn, schema)
}
\arguments{
\item{conn}{Connection object created with RPostgreSQL}

\item{schema}{String. Name of the schema that stores or will store 
the pgtraj data model}
}
\value{
TRUE on success, otherwise warning/error
}
\description{
Used by \code{pgTrajDB2TempT} and \code{pgTrajR2TempT} to create a 
temporary table which will be populated by these functions. The 
temporary table's name is a random string to avoid collation with 
user generated tables.
}
\examples{
\dontrun{pgTrajTempT(conn, "traj_1")}
}
\author{
Balázs Dukai \email{balazs.dukai@gmail.com}
}
\keyword{internal}
