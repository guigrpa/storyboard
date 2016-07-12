-- DROP DATABASE storyboard

CREATE DATABASE storyboard
  WITH ENCODING='UTF8'
       CONNECTION LIMIT=-1;

-- DROP TABLE "logEntries";

CREATE TABLE IF NOT EXISTS "logEntries"
(
  -- Common to stories and logs
  id serial NOT NULL,
  "hubId" character varying(255),
  version integer,
  "fStory" boolean,
  "fServer" boolean,
  "storyId" character varying(255),
  t timestamp with time zone,
  src character varying(255),
  level integer,

  -- Stories-only
  "fRoot" boolean,
  title text,
  action character varying(255),
  parents jsonb,

  -- Logs-only
  msg text,
  obj jsonb,
  "objExpanded" boolean,
  "objLevel" integer,
  "objOptions" jsonb,
  "objIsError" boolean,

  CONSTRAINT "logEntries_pkey" PRIMARY KEY (id)
);
