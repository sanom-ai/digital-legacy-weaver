export type PolicyDecision = {
  allowed: boolean;
  required: string[];
  requiredControls: RequirementControl[];
  reasons: string[];
};

export type RequirementControl = {
  name: string;
  mode: "strict" | "advisory";
  risk?: "low" | "medium" | "high" | "critical";
  evidence?: string;
  owner?: string;
};

type AuthorityRule = {
  allow: Set<string>;
  deny: Set<string>;
  require: Map<string, Map<string, RequirementControl>>;
};

type ConstraintRule = {
  forbid: Array<{ role: string; action: string }>;
  require: Map<string, Map<string, RequirementControl>>;
};

type CompiledPolicy = {
  authorities: Map<string, AuthorityRule>;
  constraints: ConstraintRule[];
};

function ensureAuthority(map: Map<string, AuthorityRule>, role: string): AuthorityRule {
  const current = map.get(role);
  if (current) return current;
  const fresh: AuthorityRule = { allow: new Set(), deny: new Set(), require: new Map() };
  map.set(role, fresh);
  return fresh;
}

function parseCsvList(raw: string): string[] {
  return raw
    .split(",")
    .map((v) => v.trim())
    .filter(Boolean);
}

function parseRequirementToken(raw: string): string {
  const requirementExpr = raw.trim();
  const bracketIndex = requirementExpr.indexOf("[");
  if (bracketIndex <= 0) return requirementExpr;
  return requirementExpr.slice(0, bracketIndex).trim();
}

function parseRequirementControl(raw: string): RequirementControl {
  const requirementExpr = raw.trim();
  const bracketIndex = requirementExpr.indexOf("[");
  const name = parseRequirementToken(requirementExpr);
  const control: RequirementControl = {
    name,
    mode: "strict",
  };
  if (bracketIndex <= 0) return control;

  const closeIndex = requirementExpr.lastIndexOf("]");
  if (closeIndex <= bracketIndex) return control;
  const metadataRaw = requirementExpr.slice(bracketIndex + 1, closeIndex).trim();
  if (!metadataRaw) return control;

  const pairs = metadataRaw.split(",");
  for (const pair of pairs) {
    const part = pair.trim();
    if (!part) continue;
    const eq = part.indexOf("=");
    if (eq <= 0) continue;
    const key = part.slice(0, eq).trim();
    const value = part.slice(eq + 1).trim();
    if (key === "mode" && (value === "strict" || value === "advisory")) {
      control.mode = value;
      continue;
    }
    if (key === "risk" && (value === "low" || value === "medium" || value === "high" || value === "critical")) {
      control.risk = value;
      continue;
    }
    if (key === "evidence") {
      control.evidence = value;
      continue;
    }
    if (key === "owner") {
      control.owner = value;
      continue;
    }
  }

  return control;
}

export function compilePTN(source: string): CompiledPolicy {
  const authorities = new Map<string, AuthorityRule>();
  const constraints: ConstraintRule[] = [];

  const lines = source.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  let currentType = "";
  let currentId = "";
  let currentConstraint: ConstraintRule | null = null;

  for (const line of lines) {
    const blockStart = line.match(/^(role|authority|constraint|policy)\s+([A-Za-z0-9_-]+)\s*\{$/);
    if (blockStart) {
      currentType = blockStart[1];
      currentId = blockStart[2];
      if (currentType === "constraint") {
        currentConstraint = { forbid: [], require: new Map() };
      }
      continue;
    }

    if (line === "}") {
      if (currentType === "constraint" && currentConstraint) {
        constraints.push(currentConstraint);
      }
      currentType = "";
      currentId = "";
      currentConstraint = null;
      continue;
    }

    if (currentType === "authority") {
      const authority = ensureAuthority(authorities, currentId);
      if (line.startsWith("allow:")) {
        parseCsvList(line.replace("allow:", "")).forEach((action) => authority.allow.add(action));
        continue;
      }
      if (line.startsWith("deny:")) {
        parseCsvList(line.replace("deny:", "")).forEach((action) => authority.deny.add(action));
        continue;
      }
      const requireMatch = line.match(/^require\s+([A-Za-z0-9_:-]+(?:\[[^\]]+\])?)\s+for\s+([A-Za-z0-9_:-]+)$/);
      if (requireMatch) {
        const requirement = parseRequirementControl(requireMatch[1]);
        const action = requireMatch[2];
        const map = authority.require.get(action) ?? new Map<string, RequirementControl>();
        map.set(requirement.name, requirement);
        authority.require.set(action, map);
      }
      continue;
    }

    if (currentType === "constraint" && currentConstraint) {
      const forbidMatch = line.match(/^forbid\s+([A-Za-z0-9_:-]+)\s+to\s+([A-Za-z0-9_:-]+)$/);
      if (forbidMatch) {
        currentConstraint.forbid.push({ role: forbidMatch[1], action: forbidMatch[2] });
        continue;
      }
      const requireMatch = line.match(/^require\s+([A-Za-z0-9_:-]+(?:\[[^\]]+\])?)\s+for\s+([A-Za-z0-9_:-]+)$/);
      if (requireMatch) {
        const requirement = parseRequirementControl(requireMatch[1]);
        const action = requireMatch[2];
        const map = currentConstraint.require.get(action) ?? new Map<string, RequirementControl>();
        map.set(requirement.name, requirement);
        currentConstraint.require.set(action, map);
      }
    }
  }

  return { authorities, constraints };
}

export function evaluatePolicy(
  compiled: CompiledPolicy,
  role: string,
  action: string,
): PolicyDecision {
  const reasons: string[] = [];
  const requiredMap = new Map<string, RequirementControl>();

  const authority = compiled.authorities.get(role);
  if (!authority) {
      return {
        allowed: false,
        required: [],
        requiredControls: [],
        reasons: [`no authority block for role '${role}'`],
      };
  }

  for (const constraint of compiled.constraints) {
    if (constraint.forbid.some((f) => f.role === role && f.action === action)) {
      return {
        allowed: false,
        required: [],
        requiredControls: [],
        reasons: [`forbidden by constraint for ${role}:${action}`],
      };
    }
    for (const req of constraint.require.get(action)?.values() ?? []) {
      requiredMap.set(req.name, req);
    }
  }

  if (authority.deny.has(action)) {
    return {
      allowed: false,
      required: [],
      requiredControls: [],
      reasons: [`denied by authority for ${role}:${action}`],
    };
  }

  if (!authority.allow.has(action)) {
    return {
      allowed: false,
      required: [],
      requiredControls: [],
      reasons: [`action '${action}' not in allow list for role '${role}'`],
    };
  }

  for (const req of authority.require.get(action)?.values() ?? []) {
    requiredMap.set(req.name, req);
  }

  if (requiredMap.size > 0) {
    reasons.push("requirements must be satisfied before execution");
  }

  const requiredControls = [...requiredMap.values()];

  return {
    allowed: true,
    required: requiredControls.map((control) => control.name),
    requiredControls,
    reasons,
  };
}
