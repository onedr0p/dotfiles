# DISABLE_TELEMETRY and DO_NOT_TRACK also disable the feature-flag evaluation
# that Claude Code's Remote Control depends on; DISABLE_ERROR_REPORTING doesn't.
set -gx DISABLE_TELEMETRY 1
set -gx DO_NOT_TRACK 1
set -gx DISABLE_ERROR_REPORTING 1
set -gx CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY 1
set -gx DISABLE_FEEDBACK_COMMAND 1
