import type { BaseLayoutProps } from "fumadocs-ui/layouts/shared";
import { Shield } from "lucide-react";

export const baseOptions: BaseLayoutProps = {
  nav: {
    title: (
      <>
        <Shield className="size-5" />
        <span className="font-semibold">Custos</span>
      </>
    ),
  },
  links: [
    {
      text: "Documentation",
      url: "/docs",
      active: "nested-url",
    },
    {
      text: "GitHub",
      url: "https://github.com/custos-auth/custos",
      external: true,
    },
  ],
};
