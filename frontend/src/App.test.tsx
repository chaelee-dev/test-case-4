import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Routes, Route, Outlet } from "react-router-dom";
import { App } from "@/App";

describe("App", () => {
  it("renders footer with conduit branding", () => {
    render(
      <MemoryRouter>
        <Routes>
          <Route path="/" element={<App />}>
            <Route index element={<div>Home placeholder</div>} />
          </Route>
        </Routes>
      </MemoryRouter>
    );
    expect(screen.getAllByText(/conduit/i).length).toBeGreaterThan(0);
    expect(screen.getByText(/Thinkster/)).toBeInTheDocument();
  });
});
