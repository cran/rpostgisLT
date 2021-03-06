# pgtrajSchema

#' Check/create pgtraj schema.
#'
#' Checks if the provided schema is a valid pgtraj schema, and
#' creates one if it does not exist.
#'
#' Creates a schema to store \code{pgtraj}s in the database by
#' calling a SQL script from \code{./sql/traj_schema.sql}. The schema
#' name defaults to \code{traj}. If a schema with the provided name
#' already exists in the database, it checks if it contains all the
#' required tables. The function does not attempt to repair the
#' schema if all pgtraj tables are not present (e.g. because some
#' were manually deleted).  In this case, a new pgtraj schema needs
#' to be created, or the existing schema needs to be deleted and
#' recreated.
#'
#' The function has its own standalone transaction control.
#'
#' @param conn Connection object created with RPostgreSQL.
#' @param schema Character string. Name of the schema that stores or
#'     will store the pgtraj data model.
#' @return \code{TRUE} if the schema exists (whether it was already
#'     available or was successfully created).
#' @author Balázs Dukai \email{balazs.dukai@@gmail.com}
#' @export
#' @examples
#' \dontrun{
#'   # Check (or create) pgtraj schema with name "traj_1"
#'   pgtrajSchema(conn,"traj_1")
#' }

pgtrajSchema <- function(conn, schema = "traj") {
    ## check PostgreSQL connection
    dbConnCheck(conn)
    ## Check if PostGIS is enabled
    if (!suppressMessages(pgPostGIS(conn))) {
        stop("PostGIS is not enabled on this database.")
    }
    ## Begin transaction block
    invisible(dbExecute(conn, "BEGIN TRANSACTION;"))
    ## Check and/or create schema
    dbSchema(conn, schema, display = FALSE, exec = TRUE)
    # Is the traj schema in the DB or just created and empty
    sql_query <-
        paste0(
            "SELECT tablename FROM pg_tables WHERE schemaname=",
            dbQuoteString(conn, schema),
            ";"
        )
    dbtables <-
        dbGetQuery(conn, sql_query, stringsAsFactors = FALSE)
    dbtables <- dbtables$tablename
    traj_tables <- c("animal_burst", "pgtraj", "step", "s_b_rel",
                     "relocation")
    if (length(dbtables) == 0) {
        ## In case of empty schema, set DB search path for the schema
        current_search_path <- dbGetQuery(conn, "SHOW search_path;")
        sql_query <-
            paste0("SET search_path TO ",
                   dbQuoteIdentifier(conn,
                                     schema),
                   ",public;")
        invisible(dbExecute(conn, sql_query))
        ## SQL query to set up schema
        pgtraj_schema_file <-
            system.file("sql/traj_schema.sql", package = "rpostgisLT")
        psf <- readLines(pgtraj_schema_file, encoding = "UTF-8")
        psf[psf == ""] <- "%SPLITHERE%"
        psf <- paste(psf, collapse = "\n")
        sql_query <- unlist(strsplit(psf, "%SPLITHERE%", fixed = TRUE))
        for (sq in sql_query) {
            invisible(dbExecute(conn, sq))
        }
        ## create summary views
        trajSummaryViews(conn, schema)
        ## Reset DB search path to the public schema
        sql_query <-
            paste0("SET search_path TO ", current_search_path,
                   ";")
        invisible(dbExecute(conn, sql_query))
        ## Commit transaction block
        invisible(dbCommit(conn))
        message(
            paste0(
                "The pgtraj schema '",
                schema,
                "' was successfully created in the database."
            )
        )
        return(TRUE)
    } else if (all(traj_tables %in% dbtables)) {
        # All required tables are present in the schema
        invisible(dbCommit(conn))
        # message(paste0('The schema '', schema, '' already exists in
        # the database, and is a valid pgtraj schema.'))
        return(TRUE)
    } else {
        invisible(dbRollback(conn))
        stop(
            paste0(
                "A schema '",
                schema,
                "' already exists in the database, and is not a valid pgtraj schema."
            )
        )
    }
}