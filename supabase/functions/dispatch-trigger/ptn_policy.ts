export type PolicyDecision = {
  allowed: boolean;
  required: string[];
  reasons: string[];
};

type AuthorityRule = {
  allow: Set<string>;
  deny: Set<string>;
  require: Map<string, Set<string>>;
};

type ConstraintRule = {
  forbid: Array<{ role: string; action: string }>;
  require: Map<string, Set<string>>;
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
      const requireMatch = line.match(/^require\s+([A-Za-z0-9_:-]+)\s+for\s+([A-Za-z0-9_:-]+)$/);
      if (requireMatch) {
        const requirement = requireMatch[1];
        const action = requireMatch[2];
        const set = authority.require.get(action) ?? new Set<string>();
        set.add(requirement);
        authority.require.set(action, set);
      }
      continue;
    }

    if (currentType === "constraint" && currentConstraint) {
      const forbidMatch = line.match(/^forbid\s+([A-Za-z0-9_:-]+)\s+to\s+([A-Za-z0-9_:-]+)$/);
      if (forbidMatch) {
        currentConstraint.forbid.push({ role: forbidMatch[1], action: forbidMatch[2] });
        continue;
      }
      const requireMatch = line.match(/^require\s+([A-Za-z0-9_:-]+)\s+for\s+([A-Za-z0-9_:-]+)$/);
      if (requireMatch) {
        const requirement = requireMatch[1];
        const action = requireMatch[2];
        const set = currentConstraint.require.get(action) ?? new Set<string>();
        set.add(requirement);
        currentConstraint.require.set(action, set);
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
  const required = new Set<string>();

  const authority = compiled.authorities.get(role);
  if (!authority) {
    return {
      allowed: false,
      required: [],
      reasons: [`no authority block for role '${role}'`],
    };
  }

  for (const constraint of compiled.constraints) {
    if (constraint.forbid.some((f) => f.role === role && f.action === action)) {
      return {
        allowed: false,
        required: [],
        reasons: [`forbidden by constraint for ${role}:${action}`],
      };
    }
    for (const req of constraint.require.get(action) ?? []) {
      required.add(req);
    }
  }

  if (authority.deny.has(action)) {
    return {
      allowed: false,
      required: [],
      reasons: [`denied by authority for ${role}:${action}`],
    };
  }

  if (!authority.allow.has(action)) {
    return {
      allowed: false,
      required: [],
      reasons: [`action '${action}' not in allow list for role '${role}'`],
    };
  }

  for (const req of authority.require.get(action) ?? []) {
    required.add(req);
  }

  if (required.size > 0) {
    reasons.push("requirements must be satisfied before execution");
  }

  return {
    allowed: true,
    required: [...required],
    reasons,
  };
}
