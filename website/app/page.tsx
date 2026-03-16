import Link from "next/link";
import { Shield, Plug, Key, Lock } from "lucide-react";

export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center px-4 text-center">
      <div className="max-w-2xl space-y-6 py-20">
        <div className="flex justify-center">
          <Shield className="size-16 text-fd-primary" />
        </div>
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          Custos
        </h1>
        <p className="text-lg text-fd-muted-foreground">
          Plugin-based authentication for Ruby on Rails. Inspired by Rodauth's
          modularity and Devise's per-model configuration.
        </p>
        <div className="flex flex-col gap-3 sm:flex-row sm:justify-center">
          <Link
            href="/docs"
            className="inline-flex items-center justify-center rounded-lg bg-fd-primary px-6 py-3 text-sm font-medium text-fd-primary-foreground transition-colors hover:bg-fd-primary/90"
          >
            Get Started
          </Link>
          <Link
            href="https://github.com/custos-auth/custos"
            className="inline-flex items-center justify-center rounded-lg border border-fd-border px-6 py-3 text-sm font-medium transition-colors hover:bg-fd-accent"
          >
            View on GitHub
          </Link>
        </div>
        <div className="grid grid-cols-1 gap-4 pt-10 sm:grid-cols-3">
          <div className="rounded-lg border border-fd-border p-6">
            <Plug className="mx-auto mb-3 size-8 text-fd-primary" />
            <h3 className="font-semibold">Plugin Architecture</h3>
            <p className="mt-2 text-sm text-fd-muted-foreground">
              Only include what you need. Each feature is an independent plugin.
            </p>
          </div>
          <div className="rounded-lg border border-fd-border p-6">
            <Key className="mx-auto mb-3 size-8 text-fd-primary" />
            <h3 className="font-semibold">Per-Model Config</h3>
            <p className="mt-2 text-sm text-fd-muted-foreground">
              Different models, different auth strategies. Configure each
              independently.
            </p>
          </div>
          <div className="rounded-lg border border-fd-border p-6">
            <Lock className="mx-auto mb-3 size-8 text-fd-primary" />
            <h3 className="font-semibold">Security First</h3>
            <p className="mt-2 text-sm text-fd-muted-foreground">
              Argon2 hashing, timing-safe comparisons, token digests. No
              shortcuts.
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
